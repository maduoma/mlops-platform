# MLOps Platform - State Management

This directory contains Terraform state files and related artifacts for different environments.

## Directory Structure

```text
state/
├── dev/                    # Development environment state
│   ├── outputs.json       # Latest deployment outputs
│   ├── terraform.plan     # Current deployment plan (temporary)
│   └── backups/           # State backups
├── staging/               # Staging environment state
│   ├── outputs.json       # Latest deployment outputs
│   ├── terraform.plan     # Current deployment plan (temporary)
│   └── backups/           # State backups
└── production/            # Production environment state
    ├── outputs.json       # Latest deployment outputs
    ├── terraform.plan     # Current deployment plan (temporary)
    └── backups/           # State backups
```

## State Management

### Remote State Backend

Each environment uses a separate Azure Storage Account for state management:

- **Development**: `mlopsdevtfstate` storage account
- **Staging**: `mlopsstagingtfstate` storage account  
- **Production**: `mlopsprodtfstate` storage account

### Local State Files

Local state artifacts are stored in environment-specific directories:

- `outputs.json` - Latest Terraform outputs in JSON format
- `terraform.plan` - Temporary plan files (cleaned up after deployment)
- `backups/` - State backups with timestamps

## State Operations

### Using State Manager Script

The `../scripts/state-manager.sh` script provides utilities for state management:

```bash
# Show status of all environments
./scripts/state-manager.sh status

# Show status of specific environment
./scripts/state-manager.sh status dev

# Initialize backend for environment
./scripts/state-manager.sh init staging

# Create backup of state
./scripts/state-manager.sh backup production

# Show lock information
./scripts/state-manager.sh lock dev

# Force unlock state (use with caution)
./scripts/state-manager.sh unlock dev <lock-id>

# Refresh state to match real resources
./scripts/state-manager.sh refresh staging
```

### Manual State Operations

If you need to perform manual Terraform operations:

```bash
# Initialize with specific backend
cd infrastructure/azure
terraform init -backend-config=environments/dev.backend.conf

# Switch between environments
terraform init -backend-config=environments/staging.backend.conf -reconfigure

# List resources in state
terraform state list

# Show specific resource
terraform state show <resource-name>

# Pull remote state to local file
terraform state pull > state/dev/manual-backup.tfstate

# Push local state to remote
terraform state push state/dev/manual-backup.tfstate
```

## Backup Strategy

### Automated Backups

- Backups are created automatically by deployment scripts
- Backups are stored in `backups/` directory with timestamps
- Format: `terraform.tfstate.YYYYMMDD-HHMMSS`

### Manual Backups

```bash
# Create manual backup
./scripts/state-manager.sh backup production

# Or manually
terraform state pull > state/production/backups/manual-$(date +%Y%m%d-%H%M%S).tfstate
```

## Security Considerations

### State File Security

- **Never commit state files to version control**
- State files contain sensitive information including:
  - Resource IDs and configurations
  - Secrets and connection strings
  - Internal IP addresses and network topology

### Access Control

- Azure Storage Accounts use RBAC for access control
- Service principals have minimal required permissions
- State files are encrypted at rest in Azure Storage

### State Locking

- Terraform automatically locks state during operations
- Lock information is stored in Azure Storage
- Use `state-manager.sh lock` to check lock status
- Use `state-manager.sh unlock` only when necessary

## Troubleshooting

### Common Issues

1. **State Lock Issues**

   ```bash
   # Check lock status
   ./scripts/state-manager.sh lock dev
   
   # Force unlock if needed (use carefully)
   ./scripts/state-manager.sh unlock dev <lock-id>
   ```

2. **Backend Initialization Issues**

   ```bash
   # Reinitialize backend
   ./scripts/state-manager.sh init dev
   ```

3. **State Drift**

   ```bash
   # Refresh state to match reality
   ./scripts/state-manager.sh refresh dev
   ```

4. **Corrupted State**

   ```bash
   # Restore from backup
   terraform state push state/dev/backups/terraform.tfstate.YYYYMMDD-HHMMSS
   ```

### Emergency Procedures

If you need to recover from state issues:

1. **Create immediate backup** before making changes
2. **Use state manager** utilities rather than direct Terraform commands
3. **Test changes in dev** environment first
4. **Document any manual state modifications**

## Best Practices

1. **Always use deployment scripts** rather than direct Terraform commands
2. **Create backups** before major changes
3. **Review state changes** carefully in production
4. **Use state locking** to prevent concurrent modifications
5. **Monitor state file size** and clean up when necessary
6. **Regular state backups** for production environments
7. **Document any manual state operations**

## Environment-Specific Notes

### Development

- More permissive for experimentation
- State can be reset if needed
- Regular cleanup recommended

### Staging

- Should mirror production state structure
- Used for testing state migrations
- Regular backups recommended

### Production

- **CRITICAL**: Handle with extreme care
- Mandatory backups before changes
- Enhanced safety checks in deployment scripts
- Change approval process recommended
