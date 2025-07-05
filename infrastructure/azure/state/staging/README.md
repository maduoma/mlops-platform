# Staging Environment State

This directory contains Terraform state artifacts for the **staging** environment.

## Contents

- `outputs.json` - Latest deployment outputs from Terraform
- `terraform.plan` - Temporary plan files (auto-cleaned)
- `backups/` - State file backups with timestamps

## Environment Configuration

- **Backend Config**: `../environments/staging.backend.conf`
- **Variables File**: `../environments/staging.tfvars`
- **Azure Storage**: `mlopsstagingtfstate` storage account
- **Container**: `tfstate`
- **Key**: `staging/terraform.tfstate`

## Deployment

Use the staging deployment script:

```bash
./scripts/deploy-staging.sh
```

## State Management

Use the state manager utility:

```bash
# Show status
./scripts/state-manager.sh status staging

# Create backup
./scripts/state-manager.sh backup staging

# Initialize backend
./scripts/state-manager.sh init staging
```

## Staging Notes

- This environment mirrors production configuration
- Used for testing deployment processes
- Regular backups recommended before changes
- Enhanced safety checks compared to development
