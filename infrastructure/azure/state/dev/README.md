# Development Environment State

This directory contains Terraform state artifacts for the **development** environment.

## Contents

- `outputs.json` - Latest deployment outputs from Terraform
- `terraform.plan` - Temporary plan files (auto-cleaned)
- `backups/` - State file backups with timestamps

## Environment Configuration

- **Backend Config**: `../environments/dev.backend.conf`
- **Variables File**: `../environments/dev.tfvars`
- **Azure Storage**: `mlopsdevtfstate` storage account
- **Container**: `tfstate`
- **Key**: `dev/terraform.tfstate`

## Deployment

Use the development deployment script:

```bash
./scripts/deploy-dev.sh
```

## State Management

Use the state manager utility:

```bash
# Show status
./scripts/state-manager.sh status dev

# Create backup
./scripts/state-manager.sh backup dev

# Initialize backend
./scripts/state-manager.sh init dev
```

## Development Notes

- This environment is for experimentation and testing
- State can be reset if needed for testing
- Less restrictive safety checks
- Automatic cleanup of old plan files
