# Multi-Environment State Management - Deployment Guide

This guide explains how to use the professional multi-environment state management system for the MLOps Platform.

## 🏗️ Architecture Overview

The MLOps Platform uses a sophisticated multi-environment state management approach:

### Environment Structure

```text
├── environments/           # Environment-specific configurations
│   ├── dev.backend.conf   # Development backend config
│   ├── dev.tfvars         # Development variables
│   ├── staging.backend.conf
│   ├── staging.tfvars
│   ├── production.backend.conf
│   └── production.tfvars
├── scripts/               # Deployment and management scripts
│   ├── setup-azure-state.sh    # Initial Azure storage setup
│   ├── deploy-dev.sh           # Development deployment
│   ├── deploy-staging.sh       # Staging deployment
│   ├── deploy-production.sh    # Production deployment (enhanced safety)
│   └── state-manager.sh        # State management utilities
└── state/                 # Local state artifacts
    ├── dev/
    │   ├── outputs.json
    │   ├── terraform.plan (temporary)
    │   └── backups/
    ├── staging/
    │   ├── outputs.json
    │   ├── terraform.plan (temporary)
    │   └── backups/
    └── production/
        ├── outputs.json
        ├── terraform.plan (temporary)
        └── backups/
```

### State Storage Backend

Each environment uses dedicated Azure Storage Accounts:

| Environment | Storage Account       | Container | State Key                |
|-------------|----------------------|-----------|--------------------------|
| Development | `mlopsdevtfstate`    | `tfstate` | `dev/terraform.tfstate`  |
| Staging     | `mlopsstagingtfstate`| `tfstate` | `staging/terraform.tfstate` |
| Production  | `mlopsprodtfstate`   | `tfstate` | `production/terraform.tfstate` |

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have the required tools installed:

```bash
# Check prerequisites
terraform --version  # >= 1.5
az --version         # Latest Azure CLI
az account show      # Verify logged in
```

### 2. Initial Setup

Create Azure Storage Accounts for state management:

```bash
# Setup Azure storage accounts for all environments
./scripts/setup-azure-state.sh
```

### 3. Deploy Development Environment

```bash
# Deploy to development
./scripts/deploy-dev.sh
```

### 4. Deploy Staging Environment

```bash
# Deploy to staging
./scripts/deploy-staging.sh
```

### 5. Deploy Production Environment (Enhanced Safety)

```bash
# Deploy to production (requires multiple confirmations)
./scripts/deploy-production.sh
```

## 📊 State Management Operations

### Status Checking

```bash
# Check status of all environments
./scripts/state-manager.sh status

# Check specific environment
./scripts/state-manager.sh status dev
./scripts/state-manager.sh status staging
./scripts/state-manager.sh status production
```

### Backend Initialization

```bash
# Initialize backend for specific environment
./scripts/state-manager.sh init dev
./scripts/state-manager.sh init staging
./scripts/state-manager.sh init production
```

### State Backups

```bash
# Create backup before major changes
./scripts/state-manager.sh backup dev
./scripts/state-manager.sh backup staging
./scripts/state-manager.sh backup production  # ALWAYS do this for production
```

### State Locking

```bash
# Check lock status
./scripts/state-manager.sh lock dev

# Force unlock if needed (use with extreme caution)
./scripts/state-manager.sh unlock dev <lock-id>
```

### State Refresh

```bash
# Refresh state to match actual resources
./scripts/state-manager.sh refresh dev
./scripts/state-manager.sh refresh staging
./scripts/state-manager.sh refresh production
```

## 🔄 Deployment Workflows

### Development Workflow

1. **Make changes** to Terraform code
2. **Test changes** locally
3. **Deploy to dev**: `./scripts/deploy-dev.sh`
4. **Validate deployment**
5. **Iterate as needed**

### Staging Workflow

1. **Changes tested** in development
2. **Create backup**: `./scripts/state-manager.sh backup staging`
3. **Deploy to staging**: `./scripts/deploy-staging.sh`
4. **Run integration tests**
5. **Validate deployment**

### Production Workflow

1. **Changes validated** in staging
2. **Get approval** for production deployment
3. **Create backup**: `./scripts/state-manager.sh backup production`
4. **Deploy to production**: `./scripts/deploy-production.sh`
5. **Monitor deployment**
6. **Validate all systems**
7. **Document changes**

## 🛡️ Security & Safety Features

### Development Environment

- Basic safety checks
- Automatic cleanup
- Permissive for experimentation

### Staging Environment

- Enhanced validation
- Backup recommendations
- Production-like safety checks

### Production Environment

- **Multiple confirmation prompts**
- **Mandatory backup creation**
- **Enhanced validation**
- **Detailed logging**
- **Safe deployment process**

## 🔧 Manual Operations

### Direct Terraform Commands

If you need to run Terraform directly:

```bash
# Navigate to infrastructure directory
cd infrastructure/azure

# Initialize for specific environment
terraform init -backend-config=environments/dev.backend.conf

# Switch to different environment
terraform init -backend-config=environments/staging.backend.conf -reconfigure

# Plan with environment variables
terraform plan -var-file=environments/dev.tfvars

# Apply with specific plan
terraform apply dev.plan
```

### State File Operations

```bash
# List resources in current state
terraform state list

# Show specific resource details
terraform state show azurerm_resource_group.main

# Pull remote state to local file
terraform state pull > manual-backup.tfstate

# Import existing resource
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/...
```

## 📋 Best Practices

### General Guidelines

1. **Always use deployment scripts** instead of direct Terraform commands
2. **Test in development first**, then staging, then production
3. **Create backups** before major changes
4. **Review plans carefully** before applying
5. **Document all changes** and decisions

### Environment-Specific

#### Development

- Experiment freely
- Reset state when needed
- Use for testing new features

#### Staging

- Mirror production configuration
- Test deployment processes
- Validate integrations

#### Production

- **NEVER make unplanned changes**
- **Always create backups first**
- **Follow change approval process**
- **Monitor after deployment**

## 🚨 Troubleshooting

### Common Issues

#### State Lock Issues

```bash
# Check lock status
./scripts/state-manager.sh lock production

# If locked and you're sure it's safe to unlock
./scripts/state-manager.sh unlock production <lock-id>
```

#### Backend Issues

```bash
# Reinitialize backend
./scripts/state-manager.sh init production

# Or manually
terraform init -backend-config=environments/production.backend.conf -reconfigure
```

#### State Corruption

```bash
# Restore from backup
terraform state push state/production/backups/terraform.tfstate.YYYYMMDD-HHMMSS

# Or use most recent backup
ls -la state/production/backups/
terraform state push state/production/backups/terraform.tfstate.<most-recent>
```

### Emergency Procedures

#### Production State Issues

1. **STOP all operations immediately**
2. **Assess the situation**
3. **Contact infrastructure team**
4. **Create immediate backup** (if possible)
5. **Document the issue**
6. **Restore from known good backup**
7. **Validate restoration**
8. **Resume operations carefully**

## 📈 Monitoring & Maintenance

### Regular Tasks

#### Daily

- Monitor deployment status
- Check for failed deployments
- Review logs for issues

#### Weekly

- Review state file sizes
- Clean up old plan files
- Validate backup integrity

#### Monthly

- Archive old backups
- Review access permissions
- Update documentation

### Health Checks

```bash
# Check all environments
./scripts/state-manager.sh status

# Verify backups exist
ls -la state/*/backups/

# Check Azure storage accounts
az storage account list --query "[?contains(name, 'tfstate')]"
```

## 📚 Additional Resources

- [Terraform Best Practices](../README.md)
- [Azure Backend Configuration](../backend.tf)
- [Environment Variables](../environments/)
- [Module Documentation](../modules/)

## 🔗 Related Scripts

- [`setup-azure-state.sh`](../scripts/setup-azure-state.sh) - Initial Azure setup
- [`deploy-dev.sh`](../scripts/deploy-dev.sh) - Development deployment
- [`deploy-staging.sh`](../scripts/deploy-staging.sh) - Staging deployment  
- [`deploy-production.sh`](../scripts/deploy-production.sh) - Production deployment
- [`state-manager.sh`](../scripts/state-manager.sh) - State management utilities

---

**Remember**: This is a production-grade system. Always follow the proper procedures and safety checks, especially for production deployments!
