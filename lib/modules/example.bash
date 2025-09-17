#!/bin/bash

# Example module for complex plugins that need feature separation
# Usage: Load this module when your plugin has multiple distinct features

# Usage: process_example_feature "${config_value}"
process_example_feature() {
  local config_value="$1"

  log_info "Processing example feature with value: ${config_value}"

  # Your feature logic here
  if [[ -n "${config_value}" ]]; then
    log_success "Example feature processed successfully"
    return 0
  else
    log_error "Example feature requires a configuration value"
    return 1
  fi
}

# Usage: validate_example_config "${BUILDKITE_PLUGIN_MYPLUGIN_EXAMPLE_SETTING}"
validate_example_config() {
  local setting="$1"

  if [[ "${setting}" =~ ^(option1|option2|option3)$ ]]; then
    return 0
  else
    log_error "Invalid example setting: ${setting}. Must be one of: option1, option2, option3"
    return 1
  fi
}

# Usage: setup_example_environment
# Call this from your main hook to initialize this module
setup_example_environment() {
  log_info "Setting up example feature environment"

  # Module-specific setup logic here
  export EXAMPLE_FEATURE_INITIALIZED="true"

  log_success "Example feature environment ready"
}

