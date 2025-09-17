# Library structure

This directory contains shared utilities and optional modules for complex plugins.

## Core files

- **`shared.bash`**: Common utilities and logging functions
- **`plugin.bash`**: Configuration reading helpers

## When to use modules in `modules/`

- **Multiple distinct features**: When your plugin handles several unrelated tasks (auth, deploy, notify)
- **Large codebase**: When your main plugin script becomes too large (>200 lines)
- **Reusable components**: When you have functionality shared between hooks
- **Provider-specific logic**: When supporting multiple cloud providers or backends

## Examples

- **`auth.bash`**: Authentication handling
- **`deploy.bash`**: Deployment logic
- **`aws.bash`**: AWS-specific functionality
- **`gcp.bash`**: Google Cloud functionality

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
│   └── deploy.bash         # Deployment logic
└── providers/               # Provider-specific implementations (optional)
    ├── aws.bash            # AWS-specific logic
    └── gcp.bash            # Google Cloud logic
```

## Loading modules

```bash
# In your hook script
# Load feature modules
# shellcheck source=lib/modules/auth.bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/modules/auth.bash"

# Load provider-specific modules
# shellcheck source=lib/providers/aws.bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/providers/aws.bash"

# Use functions
setup_auth_environment
setup_aws_environment
```

## Simple plugins

For simple plugins with <100 lines of logic, keep everything in your main hook script and `lib/plugin.bash`. Only create modules/providers when complexity justifies the separation.
