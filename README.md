# Template Buildkite Plugin [![Build status](https://badge.buildkite.com/d673030645c7f3e7e397affddd97cfe9f93a40547ed17b6dc5.svg)](https://buildkite.com/buildkite/plugins-template)

A Buildkite plugin for something awesome

## Options

These are all the options available to configure this plugin's behaviour.

### Required

#### `mandatory` (string)

A great description of what this is supposed to do.

### Optional

#### `optional` (string)

Describe how the plugin behaviour changes if this option is not specified, allowed values and its default.

#### `numbers` (array)

An array of numeric values for processing. Each element must be a number.

#### `enabled` (boolean)

Enable or disable a specific feature. Defaults to `false`.

#### `config` (object)

Configuration object with key-value pairs.

##### `config.host` (string, required)

The hostname or IP address to connect to.

##### `config.port` (number, optional)

The port number to use for the connection. Defaults to `1234`.

##### `config.ssl` (boolean, optional)

Whether to use SSL/TLS for the connection. Defaults to `true`.

#### `timeout` (number)

Timeout value in seconds. Must be between 1 and 60 seconds.

## Examples

### Basic Usage

Minimal configuration with just the required option:

```yaml
steps:
  - label: "🔨 Basic plugin usage"
    command: "echo processing"
    plugins:
      - template#v1.0.0:
          mandatory: "required-value"
```

### With Optional Parameters

Adding optional configuration:

```yaml
steps:
  - label: "🔨 Plugin with options"
    command: "echo processing with options"
    plugins:
      - template#v1.0.0:
          mandatory: "required-value"
          optional: "custom-value"
          timeout: 45
```

### Array Processing

Handling arrays of values:

```yaml
steps:
  - label: "🔨 Array processing"
    command: "echo processing numbers"
    plugins:
      - template#v1.0.0:
          mandatory: "required-value"
          numbers: [1, 2, 3, 5, 8]
```

### Feature Toggles

Using boolean flags to control behavior:

```yaml
steps:
  - label: "🔨 Feature enabled"
    command: "echo enhanced processing"
    plugins:
      - template#v1.0.0:
          mandatory: "required-value"
          enabled: true
```

### Complex Configuration

Using nested configuration objects:

```yaml
steps:
  - label: "🔨 Complex config"
    command: "echo connecting to service"
    plugins:
      - template#v1.0.0:
          mandatory: "required-value"
          config:
            host: "api.example.com"
            port: 8080
            ssl: false
```

### Environment Variables

Referencing secrets and environment variables:

```yaml
steps:
  - label: "🔨 Using secrets"
    command: "echo authenticated processing"
    plugins:
      - template#v1.0.0:
          mandatory: "$SECRET_VALUE" # References environment variable
          timeout: 30
```

### Debug Mode

Enabling verbose logging for troubleshooting:

```yaml
steps:
  - label: "🔨 Debug mode"
    command: "echo detailed processing"
    plugins:
      - template#v1.0.0:
          mandatory: "required-value"
    env:
      BUILDKITE_PLUGIN_DEBUG: "true"
```

## Compatibility

| Elastic Stack | Agent Stack K8s | Hosted (Mac) | Hosted (Linux) | Notes |
| :-----------: | :-------------: | :----------: | :------------: | :---- |
|       ?       |        ?        |      ?       |       ?        | n/a   |

- ✅ Fully supported (all combinations of attributes have been tested to pass)
- ⚠️ Partially supported (some combinations cause errors/issues)
- ❌ Not supported

## 👩‍💻 Contributing

1. Follow the patterns established in this template
2. Add tests for new functionality
3. Update documentation for any new options
4. Ensure shellcheck passes
5. Test with the plugin tester

## Architecture

This template demonstrates modern plugin architecture:

- **`hooks/environment`**: Early validation and setup
- **`hooks/command`**: Main execution logic
- **`lib/shared.bash`**: Common utilities and logging
- **`lib/plugin.bash`**: Configuration reading helpers
- **`lib/modules/`**: Optional feature modules for complex plugins

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development guidelines.

## Developing

**Run all tests:**

```bash
docker run -it --rm -v "$PWD:/plugin:ro" buildkite/plugin-tester
```

**Validate plugin structure:**

```bash
# Replace 'your-plugin-name' with your actual plugin name
docker run -it --rm -v "$PWD:/plugin:ro" buildkite/plugin-linter --id your-plugin-name --path /plugin
```

**Run shellcheck:**

```bash
shellcheck hooks/* tests/* lib/*
```

**Run full pipeline locally** with the [Buildkite CLI](https://github.com/buildkite/cli):

```bash
bk run
```

### Getting Started

1. **Update plugin name**: Change `YOUR_PLUGIN_NAME` in `lib/plugin.bash`
2. **Customize configuration**: Modify `plugin.yml` for your options
3. **Add your logic**: Implement features in `hooks/command`
4. **Use modules**: For complex plugins, add modules in `lib/modules/`
5. **Test thoroughly**: Add tests in `tests/` directory

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
