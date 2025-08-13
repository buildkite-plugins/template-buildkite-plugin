#!/bin/bash
set -euo pipefail

PLUGIN_PREFIX="CHATGPT_PROMPTER"

# Reads either a value or a list from the given env prefix
function prefix_read_list() {
  local prefix="$1"
  local parameter="${prefix}_0"

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      echo "${!parameter}"
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    echo "${!prefix}"
  fi
}

# Reads either a value or a list from plugin config
function plugin_read_list() {
  prefix_read_list "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}


# Reads either a value or a list from plugin config into a global result array
# Returns success if values were read
function prefix_read_list_into_result() {
  local prefix="$1"
  local parameter="${prefix}_0"
  result=()

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      result+=("${!parameter}")
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    result+=("${!prefix}")
  fi

  [ ${#result[@]} -gt 0 ] || return 1
}

# Reads either a value or a list from plugin config
function plugin_read_list_into_result() {
  prefix_read_list_into_result "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}

# Reads a single value
function plugin_read_config() {
  local var="BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
  local default="${2:-}"
  echo "${!var:-$default}"
}

function validate_required_tools() { 
  local errors=0

  # Check if required tools are installed
  if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed. Please install jq to parse JSON responses." >&2
    errors=$((errors + 1))
  fi

  if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is not installed. Please install curl to make API requests." >&2
    errors=$((errors + 1))
  fi

  return ${errors}
}

function get_openai_api_key() { 
  local api_key=""

  api_key=$(plugin_read_config API_KEY "")  
  if [ -z "${api_key}" ]; then
      api_key="${OPENAI_API_KEY:-}"
    else
      api_key="${api_key}"
  fi

  # Trim any whitespace that might be causing issues
  api_key=$(echo "$api_key" | tr -d '[:space:]')
  echo "${api_key}"
}

function get_bk_api_token() {
  local bk_token=""

  bk_token=$(plugin_read_config BUILDKITE_API_TOKEN "")
  if [ -z "${bk_token}" ]; then
    # the token is not set, so we assume it is not required
    bk_token="${BUILDKITE_API_TOKEN:-}"
  else
    bk_token="${bk_token}"
  fi
  # Trim any whitespace that might be causing issues
  bk_token=$(echo "$bk_token" | tr -d '[:space:]')
  echo "${bk_token}"
}

function validate_bk_token() {
  local bk_api_token="$1" 

  # Check if the BK API token is valid
  if [ -z "${bk_api_token}" ]; then
    # the token is not set, so we assume it is not required
    return 0
  fi

  #validate token scope
  response=$(curl -H "Authorization: Bearer ${bk_api_token}" \
    -X GET "https://api.buildkite.com/v2/access-token")
  
  #check if response is 200
  if [ $? -ne 0 ]; then
    echo "❌ Error: Invalid Buildkite API token." 
    return 1
  fi

  #check if response is empty
  if [ -z "${response}" ]; then
    echo "❌ Error: Failed to validate the Buildkite API token provided."
    return 1
  fi

  if ! echo "${response}" | jq -e '.scopes' > /dev/null; then
    echo "❌ Error: Failed to validate the scope of the Buildkite API token provided."
    return 1
  fi 

  scopes=$(echo "${response}" | jq -r '.scopes[]')   
  
  # Check if token has required read scopes
  if [[ ! "${scopes}" =~ read_builds ]] || [[ ! "${scopes}" =~ read_build_logs ]]; then
    echo "❌ Error: The Buildkite API token does not have the required 'read_builds' and 'read_build_logs' scopes."
    echo "Current scopes: ${scopes}"
    return 1
  fi
  
  echo "✅ Buildkite API token is valid."
  return 0
}

function get_current_build_information() {  
  local bk_api_token="$1"
  
  # Fetch build information from Buildkite API
  response=$(curl -s -f -X GET "https://api.buildkite.com/v2/organizations/${BUILDKITE_ORGANIZATION_SLUG}/pipelines/${BUILDKITE_PIPELINE_SLUG}/builds/${BUILDKITE_BUILD_NUMBER}" \
    -H "Authorization: Bearer ${bk_api_token}" \
    -H "Content-Type: application/json" 2>/dev/null) 

  # Check if curl failed
  if [ $? -ne 0 ]; then
    echo ""
    return
  fi
  echo "${response}"
}
 
function send_prompt() {
  local api_secret_key="$1"
  local model="$2"
  local user_prompt="$3"
  local buildkite_api_token="$4"
  
  local content=$(get_user_content "${buildkite_api_token}")
  if [ -z "${content}" ]; then
    echo "❌ Error: Failed to generate build or step level information for analysis."
    return 1
  fi

  local prompt_payload
  #check if user_prompt is equal to "ping"
  if [ "${user_prompt}" == "ping" ]; then
    prompt_payload=$(ping_payload "${model}")
  else
    prompt_payload=$(format_payload "${model}" "${user_prompt}" "${content}")
  fi
  # Call the OpenAI API
  response=$(call_openapi_chatgpt "${api_secret_key}"  "${prompt_payload}")
  
  # Validate and process the response
  if ! validate_and_process_response "${response}"; then
    return 1
  fi

  # Extract and display the response content
  total_tokens=$(echo "${response}" | jq -r '.usage.total_tokens')
  echo "Summary:"
  echo "  Total tokens used: ${total_tokens}"

  ## annotate the response into the Build
  if [ "${user_prompt}" == "ping" ]; then 
    echo -e "# ChatGPT Annotation Plugin 
        ✅ Verified OpenAI token. Successfully pinged ChatGPT with model: ${model}"  \
        | buildkite-agent annotate  --style "info" --context "chatgpt-prompter"     

    return 0
  fi

  ## Generate a more elaborate annotation
  content_response=$(echo "${response}" | jq -r '.choices[0].message.content' | sed 's/^/  /') 
    echo -e "### ChatGPT Annotation Plugin"  | buildkite-agent annotate  --style "info" --context "chatgpt-prompter"    
    echo -e "${content_response}"  | buildkite-agent annotate  --style "info" --context "chatgpt-prompter" --append

  return 0
}

function validate_and_process_response() {
  local response="$1"
  
  # Check if response is empty
  if [ -z "${response}" ]; then
    echo "❌ Error: No response received from OpenAI API."
    return 1
  fi
  
  # Check if the response contains an error
  if echo "${response}" | jq -e '.error' > /dev/null; then
    echo "❌ Error: $(echo "${response}" | jq -r '.error.message')"
    return 1
  fi
  
  # Check if the response contains choices
  if ! echo "${response}" | jq -e '.choices' > /dev/null; then
    echo "❌ Error: No choices found in the response from OpenAI API."
    return 1
  fi
  
  # Check if the response contains a message
  if ! echo "${response}" | jq -e '.choices[0].message.content' > /dev/null; then
    echo "❌ Error: No message content found in the response from OpenAI API."
    return 1
  fi
  
  return 0
}

function ping_payload() { 
  local model="$1" 

  # Prepare the payload
  local payload=$(jq -n \
    --arg model "$model" \
    '{
      model: $model,
      messages: [
        { role: "user", content: "ping" }
      ],
      max_tokens: 1,
      temperature: 0.0
    }')

  echo "$payload"
}

function call_openapi_chatgpt() {
  local api_secret_key="$1"
  local payload="$2"

  # Call the OpenAI API
  response=$(curl -sS -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer ${api_secret_key}" \
    -H "Content-Type: application/json" \
    -d "${payload}")

  echo "$response" 
}

function format_payload() {
  local model="$1"
  local custom_prompt="$2"
  local user_content="$3"
  local base_prompt="You are an expert software engineer and DevOps specialist specialising in Buildkite. Please provide a detailed analysis of the build information provided."

  local payload
  # check if user prompt is not empty, append to default prompt "you are an expert."  
  if [ -n "${custom_prompt}" ]; then
      base_prompt="${base_prompt} ${custom_prompt}"
  fi 

  # Prepare the payload with prompt
  payload=$(jq -n \
    --arg model "$model" \
    --arg system_prompt "$base_prompt" \
    --arg user_content "$user_content" \
     '{
      model: $model,
      messages: [
        { role: "system", content: $system_prompt },
        { role: "user", content: $user_content }
      ]
    }') 

    echo "$payload"
}

function get_user_content() {
  local bk_api_token="$1"

 local content=""
  # Check if Buildkite API token is provided
  if [ -z "${bk_api_token}" ]; then
     # Default to a step level or command step to be passed for prompt analysis
     content=$(echo "Generating content from current step information ...")
  else
    # Get current build information from Buildkite API
    content=$(get_current_build_information "${bk_api_token}")   
  fi 
  echo "${content}"
}