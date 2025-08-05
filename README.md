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

Show how your plugin is to be used

```yaml
steps:
  - label: "🔨 Running plugin"
    command: "echo template plugin"
    plugins:
      - template#v1.0.0:
          mandatory: "value"
```

## And with other options as well

If you want to change the plugin behaviour:

```yaml
steps:
  - label: "🔨 Running plugin"
    command: "echo template plugin with options"
    plugins:
      - template#v1.0.0:
          mandatory: "value"
          optional: "example"
```

```yaml
steps:
  - label: "🔨 Array processing"
    command: "echo processing array"
    plugins:
      - template#v1.0.0:
          mandatory: "value"
          numbers: [1, 2, 3, 5, 8]
```

```yaml
steps:
  - label: "🔨 Feature toggle"
    command: "echo feature processing"
    plugins:
      - template#v1.0.0:
          mandatory: "value"
          enabled: true
```

```yaml
steps:
  - label: "🔨 Configuration"
    command: "echo processing config"
    plugins:
      - template#v1.0.0:
          mandatory: "value"
          config:
            host: "example.com"
            port: 8080
            ssl: false
```

```yaml
steps:
  - label: "🔨 Timeout handling"
    command: "echo processing with timeout"
    plugins:
      - template#v1.0.0:
          mandatory: "value"
          timeout: 30
```

## Compatibility

| Elastic Stack | Agent Stack K8s | Hosted (Mac) | Hosted (Linux) | Notes |
| :-----------: | :-------------: | :----: | :----: |:---- |
| ? | ? | ? | ? | n/a |

- ✅ Fully supported (all combinations of attributes have been tested to pass)
- ⚠️ Partially supported (some combinations cause errors/issues)
- ❌ Not supported

## 👩‍💻 Contributing

Your policy on how to contribute to the plugin!

## Developing

To run testing, shellchecks, and plugin linting, use `bk run` with the [Buildkite CLI](https://github.com/buildkite/cli):

```bash
bk run
```

Alternatively, to run just the tests, you can use the [Buildkite Plugin Tester](https://github.com/buildkite-plugins/buildkite-plugin-tester):

```bash
docker run --rm -ti -v "${PWD}":/plugin buildkite/plugin-tester:latest
```

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
