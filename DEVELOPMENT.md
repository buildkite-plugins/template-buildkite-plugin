# Plugin development guide

This guide covers best practices for developing Buildkite plugins, with examples from this modernized template.

## Code organization principles

### When to keep it simple

For plugins with <100 lines of logic:

- Keep logic in appropriate hook files (`hooks/command`, `hooks/pre-command`, etc.)
- Use shared utilities from `lib/shared.bash` and `lib/plugin.bash`
- Skip complex directory structures

### When to use modular structure

Consider modules when having:

- **Complex shared logic** across multiple hooks
- **Distinct feature areas** (auth, deploy, notify)
- **Provider-specific logic** (AWS vs GCP vs Azure implementations)
- **>200 lines** of logic in a single file

For provider-specific handling, create separate modules like `lib/modules/aws.bash`, `lib/modules/gcp.bash`, etc.

## Hook pattern usage

### Environment hook (`hooks/environment`)

**Use for complex plugins only:**

- Expensive dependency checking that should run once (`check_dependencies docker aws`)
- Authentication setup that persists across multiple hooks
- Setting up environment variables shared between pre-command, command, and post-command hooks

**Note**: Most plugins don't need an environment hook. Use `hooks/command` for simple validation and execution.

```bash
# Example: Early validation prevents later failures
validate_required_config "API token" "${api_token}"
export PLUGIN_API_TOKEN="${api_token}"
```

### Command hook (`hooks/command`)

**Use for:**

- Main plugin execution logic
- Processing that requires validated environment
- Operations that should only run once

### Other hooks

- **Pre-command**: Setup that affects the main command
- **Post-command**: Reporting, artifact handling (success path only)
- **Pre-exit**: Cleanup operations (guaranteed to run even on cancellation)

## Error handling best practices

### Use strict error handling

Always use bash strict mode to catch errors early:

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

- **`-e`**: Exit immediately if any command fails
- **`-u`**: Exit on undefined variables
- **`-o pipefail`**: Fail on any command in a pipeline

### Validation early and often

```bash
# In environment hook - fail fast
validate_required_config "registry URL" "${registry_url}"
check_dependencies docker aws

# In command hook - validate before expensive operations
if ! docker info >/dev/null 2>&1; then
  log_error "Docker daemon is not running"
  exit 1
fi
```

### Descriptive error messages

Use the provided logging helpers for consistent output:

```bash
# Bad
echo "Error: Authentication failed" >&2

# Good - use logging helpers with descriptive messages
log_error "Failed to authenticate with registry ${registry_url}. Check your credentials and network connectivity."
log_warning "AWS CLI not found, trying docker login directly"
log_info "Processing ${image_count} images"
log_success "All images pushed successfully"
```

### Graceful degradation

```bash
# Try preferred method, fall back to alternative when available
if ! command_exists aws; then
  log_warning "AWS CLI not found, trying docker login directly"
  # Alternative authentication method
fi
```

## Configuration handling

### Required vs optional

```bash
# Required - fail immediately if missing
api_url=$(plugin_read_config API_URL "")
validate_required_config "API URL" "${api_url}"

# Optional - provide sensible default
timeout=$(plugin_read_config TIMEOUT "30")
```

### Arrays and complex objects

```bash
# Handle both single values and arrays
if plugin_read_list_into_result TAGS; then
  for tag in "${result[@]}"; do
    log_info "Processing tag: ${tag}"
  done
fi
```

## Testing strategy

### Running tests and linting

**Plugin Tester** - Run all tests:

```bash
docker run -it --rm -v "$PWD:/plugin:ro" buildkite/plugin-tester
```

**Plugin Linter** - Validate plugin structure:

```bash
# Replace 'your-plugin-name' with your actual plugin name
docker run -it --rm -v "$PWD:/plugin:ro" buildkite/plugin-linter --id your-plugin-name --path /plugin
```

**ShellCheck** - Static analysis for shell scripts:

```bash
shellcheck hooks/* tests/* lib/*.bash
```

### Unit testing with BATS

Test individual functions:

```bash
@test "validates required config" {
  export BUILDKITE_PLUGIN_MYPLUGIN_API_TOKEN=""
  run validate_required_config "API token" "${BUILDKITE_PLUGIN_MYPLUGIN_API_TOKEN}"
  assert_failure 1  # ensure it fails with exit code 1
  assert_output --partial "API token is required"
}
```

### Integration testing

Test full plugin execution with realistic scenarios:

```bash
@test "handles missing dependencies gracefully" {
  # Mock missing command
  run hooks/command
  assert_failure
  assert_output --partial "Missing required dependencies"
}
```

### Test structure

```
tests/
└── command.bats           # Plugin functionality tests
```

## Performance considerations

### Avoid expensive operations in environment hook

```bash
# Bad - slow network call in environment hook
validate_api_connectivity "${api_url}"

# Good - defer to command hook
export PLUGIN_API_URL="${api_url}"
```

### Cache expensive lookups

```bash
# Cache account ID lookup
if [[ -z "${CACHED_ACCOUNT_ID:-}" ]]; then
  CACHED_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  export CACHED_ACCOUNT_ID
fi
```

## Security considerations

### Validate input

```bash
# Prevent injection attacks
if [[ ! "${region}" =~ ^[a-z0-9-]+$ ]]; then
  log_error "Invalid region format: ${region}"
  exit 1
fi
```

### Use secure secret handling

```yaml
# In pipeline - use secrets plugin with $$VARIABLE references
plugins:
  - secrets#v1.0.0:
      variables:
        SECRET_API_TOKEN: SECRET_API_TOKEN
  - myplugin#v1.0.0:
      api-token: $$SECRET_API_TOKEN
```

## Debugging support

### Debug mode

Always support debug mode:

```bash
enable_debug_if_requested  # Enables set -x if BUILDKITE_PLUGIN_DEBUG=true
```

### Helpful logging

```bash
log_info "Authenticating with ${registry_host}"
log_info "Pushing ${image_count} images"
log_success "All images pushed successfully"
```

## Documentation

Keep README examples simple and focused. Show the most common use cases clearly rather than trying to cover every scenario.
