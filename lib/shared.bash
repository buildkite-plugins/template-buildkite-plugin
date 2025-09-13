#!/bin/bash

# Shared utility functions for Buildkite plugins

set -euo pipefail

# Usage: log_info "Starting deployment process"
log_info() {
  echo "[INFO]: $*"
}

# Usage: log_success "Image pushed to registry"
log_success() {
  echo "[SUCCESS]: $*"
}

# Usage: log_warning "Using default timeout of 30s"
log_warning() {
  echo "[WARNING]: $*"
}

# Usage: log_error "Failed to connect to API"
log_error() {
  echo "[ERROR]: $*" >&2
}

# Usage: if command_exists docker; then echo "Docker available"; fi
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Usage: check_dependencies docker aws kubectl
check_dependencies() {
  local missing_deps=()

  for cmd in "$@"; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Missing required dependencies: ${missing_deps[*]}"
    log_error "Please install the missing dependencies and try again."
    exit 1
  fi
}

# Usage: validate_required_config "API token" "${api_token}"
validate_required_config() {
  local config_name="$1"
  local config_value="$2"

  if [[ -z "$config_value" ]]; then
    log_error "$config_name is required but not provided"
    exit 1
  fi
}

# Usage: run_command "Pushing image to registry" docker push my-image:latest
run_command() {
  local description="$1"
  shift

  log_info "$description"
  if "$@"; then
    log_success "$description completed successfully"
    return 0
  else
    log_error "$description failed"
    return 1
  fi
}

# Usage: if is_debug_mode; then echo "Additional debug info"; fi
is_debug_mode() {
  [[ "${BUILDKITE_PLUGIN_DEBUG:-false}" =~ (true|on|1) ]]
}

# Usage: setup_error_trap (call early in your hook scripts)
setup_error_trap() {
  trap 'log_error "Command failed with exit status $? at line $LINENO: $BASH_COMMAND"' ERR
}

# Usage: enable_debug_if_requested (call early in your hook scripts)
enable_debug_if_requested() {
  if is_debug_mode; then
    log_info "Debug mode enabled"
    set -x
  fi
}
