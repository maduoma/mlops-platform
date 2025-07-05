# Production Environment State

This directory contains Terraform state artifacts for the **PRODUCTION** environment.

## ⚠️ CRITICAL WARNING ⚠️

**This is the PRODUCTION environment. Handle with extreme care!**

## Contents

- `outputs.json` - Latest deployment outputs from Terraform
- `terraform.plan` - Temporary plan files (auto-cleaned)
- `backups/` - State file backups with timestamps

## Environment Configuration

- **Backend Config**: `../environments/production.backend.conf`
- **Variables File**: `../environments/production.tfvars`
- **Azure Storage**: `mlopsprodtfstate` storage account
- **Container**: `tfstate`
- **Key**: `production/terraform.tfstate`

## Deployment

Use the production deployment script (with enhanced safety checks):

```bash
./scripts/deploy-production.sh
```

**Note**: The production script requires multiple confirmations and safety checks.

## State Management

Use the state manager utility:

```bash
# Show status
./scripts/state-manager.sh status production

# Create backup (ALWAYS do this before changes)
./scripts/state-manager.sh backup production

# Initialize backend
./scripts/state-manager.sh init production
```

## Production Safety Requirements

1. **ALWAYS create backups** before any changes
2. **Review all plans carefully** before applying
3. **Test changes in staging first**
4. **Follow change approval process**
5. **Monitor systems after deployment**
6. **Document all changes**

## Emergency Contacts

- **Infrastructure Team**: [Your team contact]
- **On-Call Engineer**: [On-call contact]
- **Incident Management**: [Incident process]

## Production Notes

- **Zero tolerance for unplanned changes**
- **Mandatory backup before any operation**
- **Enhanced safety checks and confirmations**
- **Change approval process required**
- **24/7 monitoring and alerting**
