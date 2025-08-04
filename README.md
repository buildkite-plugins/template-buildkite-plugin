# ChatGPT Prompter Buildkite Plugin [![Build status](https://badge.buildkite.com/d673030645c7f3e7e397affddd97cfe9f93a40547ed17b6dc5.svg)](https://buildkite.com/buildkite/plugins-template)

A Buildkite plugin that allows the user to send a prompt to ChatGPT

## Options

These are all the options available to configure this plugin's behaviour.

### Required

#### `api_secret_key_name` (string)

The name of the Buildkite secret key that contains your OpenAI API token to use for ChatGPT access. 

### Optional

#### `model` (string)

The ChatGPT model. Defaults to `GPT-4o mini`.

#### `user_prompt` (string)

The user prompt to send to ChatGPT. Defaults to "ping" the ChatGPT API.

Example of the default payload sent on a ping: 

```
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {"role": "user", "content": "ping"}
  ],
  "max_tokens": 1,
  "temperature": 0
}
```

#### `system_prompt` (string)

An option to provide a system prompt to ChatGPT together with the user prompt.

## Examples

Show how your plugin is to be used

```yaml
steps:
  - label: "🔨 Running plugin"
    command: "echo template plugin"
    plugins:
      - chatgpt-prompter#v0.0.1:
          api_secret_key_name: "CHATGPT_SECRET_KEY_NAME" 
```

## And with other options as well

If you want to change the plugin behaviour:

```yaml
steps:
  - label: "🔨 Running plugin"
    command: "echo template plugin with options"
    plugins:
      - chatgpt-prompter#v0.0.1:
          api_secret_key_name: "CHATGPT_SECRET_KEY_NAME" 
          model: "GPT-4o"
          user_prompt: "Ping"
        
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

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
