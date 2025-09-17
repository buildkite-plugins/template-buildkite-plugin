#!/bin/bash
set -euo pipefail

# Load shared utilities
# shellcheck source=lib/shared.bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/shared.bash"

# TODO: Update this to match your plugin name (uppercase, underscores)
# Example: "DOCKER_PUSH" for docker-push plugin
PLUGIN_PREFIX="YOUR_PLUGIN_NAME"

# Usage: prefix_read_list "BUILDKITE_PLUGIN_MYPLUGIN_TAGS"
# Handles both single values and arrays from plugin configuration
function prefix_read_list() {
  local prefix="$1"
  local parameter="${prefix}_0"

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      echo "${!parameter}"
      i=$((i + 1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    echo "${!prefix}"
  fi
}

# Usage: plugin_read_list TAGS
# Reads tags from BUILDKITE_PLUGIN_YOURPLUGIN_TAGS_* or BUILDKITE_PLUGIN_YOURPLUGIN_TAGS
function plugin_read_list() {
  prefix_read_list "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}

# Usage: prefix_read_list_into_result "BUILDKITE_PLUGIN_MYPLUGIN_TAGS"
# Populates global 'result' array, returns success if any values found
function prefix_read_list_into_result() {
  local prefix="$1"
  local parameter="${prefix}_0"
  result=()

  if [ -n "${!parameter:-}" ]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [ -n "${!parameter:-}" ]; do
      result+=("${!parameter}")
      i=$((i + 1))
      parameter="${prefix}_${i}"
    done
  elif [ -n "${!prefix:-}" ]; then
    result+=("${!prefix}")
  fi

  [ ${#result[@]} -gt 0 ] || return 1
}

# Usage: if plugin_read_list_into_result NUMBERS; then process_numbers "${result[@]}"; fi
# Populates global 'result' array with plugin config values, returns success if any values found
function plugin_read_list_into_result() {
  prefix_read_list_into_result "BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
}

# Usage: timeout=$(plugin_read_config TIMEOUT "30")
# Gets plugin config value with optional default
function plugin_read_config() {
  local var="BUILDKITE_PLUGIN_${PLUGIN_PREFIX}_${1}"
  local default="${2:-}"
  echo "${!var:-$default}"
}
