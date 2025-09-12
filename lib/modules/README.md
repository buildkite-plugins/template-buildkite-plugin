# Plugin modules and providers

This directory structure supports complex plugins with multiple features or cloud providers.

## Directory usage

- **`lib/modules/`**: Feature-specific functionality (auth, deploy, notify)
- **`lib/providers/`**: Cloud provider implementations (aws, gcp, azure)

## When to use modules

- **Multiple distinct features**: When your plugin handles several unrelated tasks
- **Large codebase**: When your main plugin script becomes too large (>200 lines)
- **Reusable components**: When you have functionality that could be shared between hooks

## When to use providers

- **Multiple cloud providers**: Supporting AWS, GCP, Azure, etc.
- **Different backends**: Various registries, APIs, or services
- **Provider-specific logic**: Each provider has unique authentication/configuration

## Module pattern

Each module should:

1. **Focus on one feature area** (e.g., authentication, deployment, notification)
2. **Provide clear function interfaces** with usage comments
3. **Handle its own validation and setup**
4. **Use shared utilities** from `lib/shared.bash`

## Example structure

```bash
lib/
├── shared.bash              # Common utilities used everywhere
├── plugin.bash              # Configuration helpers
├── modules/                 # Feature modules
│   ├── auth.bash           # Authentication handling
│   ├── deploy.bash         # Deployment logic
│   └── notifications.bash  # Notification sending
└── providers/              # Provider implementations
    ├── aws.bash            # AWS-specific logic
    ├── gcp.bash            # Google Cloud logic
    └── azure.bash          # Azure-specific logic
```

## Loading modules/providers

```bash
# In your hook script
# shellcheck source=lib/modules/auth.bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/modules/auth.bash"

# shellcheck source=lib/providers/aws.bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/providers/aws.bash"

# Use functions
setup_auth_environment
setup_aws_environment
```

## Simple plugins

For simple plugins with <100 lines of logic, keep everything in your main hook script and `lib/plugin.bash`. Only create modules/providers when complexity justifies the separation.
