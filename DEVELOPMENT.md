# Plugin development guide

This guide covers best practices for developing Buildkite plugins, with examples from this modernized template.

## Code organization principles

### When to keep it simple

For plugins with <100 lines of logic:

- Keep everything in `hooks/command` and `lib/plugin.bash`
- Use shared utilities from `lib/shared.bash`
- Skip complex directory structures

### When to use modular structure

Consider modules when having:

- **Distinct feature areas** (auth, deploy, notify)
- **Reusable components** across multiple hooks
- **>200 lines** of logic in a single file

Consider providers when having:

- **Multiple cloud providers** (AWS, GCP, Azure)
- **Different backends** (various registries, APIs, services)
- **Provider-specific logic** with unique authentication/configuration

## Hook pattern usage

### Environment hook (`hooks/environment`)

**Use for:**

- Early validation of required configuration
- Dependency checking (`check_dependencies docker aws`)
- Setting up environment variables for later hooks
- Authentication setup that persists across hooks

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
- **Post-command**: Cleanup, reporting, artifact handling

## Error handling best practices

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

```bash
# Bad
log_error "Authentication failed"

# Good
log_error "Failed to authenticate with registry ${registry_url}. Check your credentials and network connectivity."
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

### Environment variables

Handle `$VARIABLE_NAME` references in configuration:

```bash
token=$(expand_env_var "${raw_token}" "api-token")
```

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
shellcheck hooks/* tests/* lib/*
```

### Unit testing with BATS

Test individual functions:

```bash
@test "validates required config" {
  export BUILDKITE_PLUGIN_MYPLUGIN_API_TOKEN=""
  run validate_required_config "API token" "${BUILDKITE_PLUGIN_MYPLUGIN_API_TOKEN}"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "API token is required" ]]
}
```

### Integration testing

Test full plugin execution with realistic scenarios:

```bash
@test "handles missing dependencies gracefully" {
  # Mock missing command
  run hooks/command
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing required dependencies" ]]
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

### Use environment variables for secrets

```yaml
# In pipeline
plugins:
  - myplugin#v1.0.0:
      api-token: "$SECRET_API_TOKEN" # Reference env var
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

### README examples

Show progression from simple to complex:

1. Minimal required configuration
2. Common use cases with optional parameters
3. Advanced scenarios with full configuration
