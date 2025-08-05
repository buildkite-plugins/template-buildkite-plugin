#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  # Uncomment to enable stub debugging
  # export CURL_STUB_DEBUG=/dev/tty

  # you can set variables common to all tests here
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_MANDATORY='Value'
}

@test "Missing mandatory option fails" {
  unset BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_MANDATORY

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'Missing mandatory option'
  refute_output --partial 'Running plugin'
}

@test "Normal basic operations" {

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- mandatory: Value'
}

@test "Optional value changes bejaviour" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_OPTIONAL='other value'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- optional: other value'
}

@test "Numbers array processing" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_NUMBERS_0='1'
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_NUMBERS_1='2'
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_NUMBERS_2='3'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- numbers: 1, 2, 3'
}

@test "Enabled boolean feature toggle" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_ENABLED='true'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- enabled: true'
}

@test "Config object with nested properties" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_CONFIG_HOST='example.com'
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_CONFIG_PORT='8080'
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_CONFIG_SSL='true'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- config.host: example.com'
  assert_output --partial '- config.port: 8080'
  assert_output --partial '- config.ssl: true'
}

@test "Timeout number validation" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_TIMEOUT='30'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- timeout: 30'
}

@test "Timeout exceeds maximum fails" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_TIMEOUT='100'

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'Error: timeout must be between 1 and 60 seconds'
  refute_output --partial 'Running plugin with options'
}

@test "Timeout below minimum fails" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_TIMEOUT='0'

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'Error: timeout must be between 1 and 60 seconds'
  refute_output --partial 'Running plugin with options'
}

@test "Shows default values when not specified" {
  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- enabled: false'
}

@test "Config with only required host field" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_CONFIG_HOST='test.com'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- config.host: test.com'
  assert_output --partial '- config.port: 1234'
  assert_output --partial '- config.ssl: true'
}

@test "Handles missing numbers array gracefully" {
  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  refute_output --partial '- numbers:'
}

@test "Enabled boolean set to false explicitly" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_ENABLED='false'

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running plugin with options'
  assert_output --partial '- enabled: false'
}

@test "Numbers array with non-numeric element fails" {
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_NUMBERS_0='1'
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_NUMBERS_1='abc'
  export BUILDKITE_PLUGIN_YOUR_PLUGIN_NAME_NUMBERS_2='3'

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'Error: numbers array contains non-numeric value: abc'
  refute_output --partial 'Running plugin with options'
}
