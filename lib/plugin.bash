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

function validate_bk_token() {
  local bk_api_token="$1"
  local errors=0

  # Check if the BK API token is valid
  if [ -z "${bk_api_token}" ]; then
    echo "❌ Error: Missing Buildkite API token."
    errors=$((errors + 1))
  fi

  #validate token scope
  response=$(curl -H "Authorization: Bearer ${bk_api_token}" \
    -X GET "https://api.buildkite.com/v2/access-token")
 

  echo "--- Buildkite API Token Scopes ---"
  echo "${response}" | jq -r '.scopes[]'


  scopes=$(echo "${response}" | jq -r '.scopes[]')
  if [[ "${scopes}" =~ write ]]; then
    echo "❌ Error: The Buildkite API token has write permissions which are not allowed for security reasons."
    errors=$((errors + 1))
  fi
  echo "✅ Buildkite API token is valid and has appropriate read-only scopes."
  return ${error}
}

function send_prompt() {
  local api_secret_key="$1"
  local model="$2"
  local user_prompt="$3"
  local system_prompt="$4"

  local prompt_payload
  #check if user_prompt is equal to "ping"
  if [ "${user_prompt}" == "ping" ]; then
    prompt_payload=$(ping_payload "${model}")
  else
    prompt_payload=$(format_payload "${model}" "${user_prompt}" "${system_prompt}")
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
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed. Please install jq to parse the response from OpenAI API."
    return 1
  fi
  
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
  local user_prompt="$2"
  local system_prompt="$3"

  local payload
  if [ -z "${system_prompt}" ]; then
      # Prepare the payload without system prompt
      payload=$(jq -n \
        --arg model "$model" \
        --arg user_prompt "$user_prompt" \
        '{
          model: $model,
          messages: [
            { role: "user", content: $user_prompt }
          ] 
        }')
    else
      # Prepare the payload with system prompt
      payload=$(jq -n \
        --arg model "$model" \
        --arg user_prompt "$user_prompt" \
        --arg system_prompt "$system_prompt" \
        '{
          model: $model,
          messages: [
            { role: "system", content: $system_prompt },
            { role: "user", content: $user_prompt }
          ]
        }')
    fi
    echo "$payload"
}