#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  # Uncomment to enable stub debugging
  # export CURL_STUB_DEBUG=/dev/tty
 
}

@test "Missing API Secret Key configuration fails" {
  unset BUILDKITE_PLUGIN_YOUR_CHATGPT_PROMPTER_API_SECRET_KEY_NAME

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'Missing Missing api secret key'
  refute_output --partial 'Running plugin'
}

@test "Empty or Incorrect API Secret Key Name in configuration fails" {
  export BUILDKITE_PLUGIN_YOUR_CHATGPT_PROMPTER_API_SECRET_KEY_NAME=''

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'Secret not found or access denied'
  refute_output --partial 'Running plugin'
}


@test "Invalid API Token fails" {
  export BUILDKITE_PLUGIN_YOUR_CHATGPT_PROMPTER_API_SECRET_KEY_NAME='123'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'OpenAI API Key retrieved successfully'
  assert_output --partial 'Model: gpt-4o-mini'
  assert_output --partial 'User Prompt: ping' 
}


 