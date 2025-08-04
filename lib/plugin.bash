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

function send_prompt() {
  local api_secret_key="$1"
  local model="$2"
  local user_prompt="$3"
  local system_prompt="$4"

  local prompt_payload
  #check if user_prompt is equal to "ping"
  if [ "${user_prompt}" == "ping" ]; then
    echo "Pinging ChatGPT with model: ${model}"
    prompt_payload=$(ping_payload "${model}")
  else
    prompt_payload=$(format_payload "${model}" "${user_prompt}" "${system_prompt}")
  fi
  # Call the OpenAI API
  response=$(call_openapi_chatgpt "${api_secret_key}"  "${prompt_payload}")
  echo "Response from ChatGPT:"
  #assign response to a variable and check if it is empty
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
  # Print the message content
  echo "ChatGPT Response:"
  # Use jq to extract the message content from the response
  if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed. Please install jq to parse the response from OpenAI API."
    return 1
  fi
  # Print the message content
  echo "~~~"
  echo "ChatGPT Response:"
  content_response=$(echo "${response}" | jq -r '.choices[0].message.content' | sed 's/^/  /') 
  buildkite-agent annotate --style "info" --context "chatgpt-prompter" \
    "ChatGPT Response:\n\n${content_response}"
  echo "✅ Successfully sent prompt to ChatGPT."
  return 0
}

function ping_payload() { 
  local model="$1" 

  echo "Pinging ChatGPT with model: ${model}"
  
  # Prepare the payload
  local payload=$(jq -n \
    --arg model "$model" \
    '{
      model: $model,
      messages: [
        { role: "user", content: "ping" }, 
      ],
      max_tokens: 1,
      temperature: 0.0,
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
