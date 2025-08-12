# ChatGPT Prompter Buildkite Plugin [![Build status](https://badge.buildkite.com/d673030645c7f3e7e397affddd97cfe9f93a40547ed17b6dc5.svg)](https://buildkite.com/buildkite/plugins-template)

A Buildkite plugin that allows the user to send a prompt to ChatGPT

## Requirements

### Tools
- **curl**: For API requests
- **jq**: For JSON processing
- **OpenAI API Key**: For sending ChatGPT prompts. Create an OpenAI platform account from [OpenAI account](http://platform.openai.com/login), or log in to an existing one. Generate an OpenAI API Key from the OpenAI dashboard -> View OpenAI Keys menu. 
     
 
## Examples

### Using environment variable set at upload time 

Add the OpenAI API Key to your Buildkite environment variable as `OPENAI_API_KEY`

```
steps:
  - label: "🔍 Prompt ChatGPT to summarise test results"
    command: "npm test"
    plugins:
      - chatgpt-prompter#v0.0.1:
          api_key: "$$OPENAI_API_KEY" 
```

### Using Buildkite secrets (recommended)

First, create .buildkite/hooks/pre-command and set the environment variables with the Buildkite secrets they are stored in. 

```
#!/bin/bash
export OPENAI_API_KEY=$(buildkite-agent secret get OPENAI_API_KEY) 
export BUILDKITE_API_TOKEN=$(buildkite-agent secret get BUILDKITE_API_TOKEN)    
```

Use the environment variables set in the plugin.

```
steps:
  - label: "🔍 Prompt ChatGPT to summarise build"
    command: echo "Summarise build"
    plugins:
      - chatgpt-prompter#v0.0.1:
          api_key: "$$OPENAI_API_KEY"
          buildkite_api_token: "$$BUILDKITE_API_TOKEN" 
```


## Configuration


### Required

#### `api_key` (string)

The name of the Buildkite secret key that contains your OpenAI API token to use for ChatGPT access. Use an environment variable reference for this.

- **Environment variable**: `"${OPENAI_API_KEY}"` - References an environment variable set at upload time
- **Buildkite secrets**: Create `.buildkite/hooks/pre-command` with `export OPENAI_API_KEY=$(buildkite-agent secret get OPENAI_API_KEY)`, then use `"$$OPENAI_API_KEY"` (recommended)


### Optional

#### `buildkite_api_token` (string)

The Buildkite API token to use for fetching build information from the Buildkite API to use for build analysis. If not specified, the plugin will look for `BUILDKITE_API_TOKEN` in the environment.


#### `model` (string)

The ChatGPT model. Defaults to `GPT-4o mini`.

#### `custom_prompt` (string)

Additional context to prompt ChatGPT for include in its analysis.   

## Examples

### Basic Usage - Analyse Current Build

```yaml
steps:
  - label: "🔍 Prompt ChatGPT to summarise build"
    command: "npm test"
    plugins:
      - chatgpt-prompter#v0.0.1:
          api_key: "$$OPENAI_API_KEY" 
```

## Provide Aditional Context  

If you want to provide additional context or instructions to the default build summary, provide a `custom_prompt` parameter to the plugin. 

```yaml
steps:
  - label: "🔍 Prompt ChatGPT to focus on build performance"
    command: "echo template plugin with options"
    plugins:
      - chatgpt-prompter#v0.0.1:
          api_key: "$$OPENAI_API_KEY"
          buildkite_api_token: "$$BUILDKITE_API_TOKEN"
          model: "GPT-4o"
          custom_prompt: "Focus on build performance and optimization opportunities"
        
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
