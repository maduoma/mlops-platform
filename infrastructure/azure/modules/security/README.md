# Security Module

This module creates and manages security infrastructure including Azure Key Vault, secrets management, access policies, and private endpoints for the MLOps platform.

## Resources Created

- **Key Vault**: Centralized secrets and key management
- **Access Policies**: Fine-grained permissions for different principals
- **Secrets**: Managed storage of sensitive configuration data
- **Private Endpoint**: Optional private connectivity for Key Vault
- **Security Configurations**: Network access rules and compliance settings

## Usage

```hcl
module "security" {
  source = "./modules/security"
  
  key_vault_name      = "mlops-kv-prod"
  resource_group_name = "mlops-rg"
  location            = "East US"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  # Access policies
  aks_principal_id       = module.aks.cluster_identity[0].principal_id
  current_user_object_id = data.azurerm_client_config.current.object_id
  
  # Network configuration
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
    subnet_ids     = [module.networking.aks_subnet_id]
  }
  
  # Private endpoint
  enable_private_endpoint    = false
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  
  # Secrets (populated after other resources)
  storage_connection_string = module.storage.storage_connection_string
  
  tags = {
    Environment = "production"
    Project     = "MLOps"
  }
}
```

## Managed Secrets

The module manages the following secrets automatically:

1. **MLflow Database Connection**: Database connection string for MLflow tracking
2. **Storage Connection String**: Azure Storage connection for artifacts
3. **ACR Admin Credentials**: Container registry access credentials (if enabled)

## Access Policies

### AKS Cluster Identity

- **Secret Permissions**: `["Get", "List"]`
- **Key Permissions**: `["Get", "List", "Decrypt", "Encrypt"]`
- **Purpose**: Allow AKS pods to retrieve secrets and keys

### Current User/Service Principal

- **Secret Permissions**: Full management permissions
- **Key Permissions**: Full management permissions  
- **Certificate Permissions**: Full management permissions
- **Purpose**: Administrative access for deployment and management

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| key_vault_name | Name of the Key Vault | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| tenant_id | Azure AD tenant ID | `string` | n/a | yes |
| key_vault_sku | Key Vault SKU | `string` | `"standard"` | no |
| soft_delete_retention_days | Soft delete retention period | `number` | `90` | no |
| purge_protection_enabled | Enable purge protection | `bool` | `true` | no |
| aks_principal_id | AKS cluster principal ID | `string` | `""` | no |
| current_user_object_id | Current user object ID | `string` | `""` | no |
| network_acls | Network access rules | `object` | See variables.tf | no |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for private endpoint | `string` | `""` | no |
| mlflow_db_connection_string | MLflow database connection | `string` | `""` | no |
| storage_connection_string | Storage connection string | `string` | `""` | no |
| acr_admin_username | ACR admin username | `string` | `""` | no |
| acr_admin_password | ACR admin password | `string` | `""` | no |
| aks_secret_permissions | AKS secret permissions | `list(string)` | `["Get", "List"]` | no |
| aks_key_permissions | AKS key permissions | `list(string)` | See variables.tf | no |
| admin_secret_permissions | Admin secret permissions | `list(string)` | See variables.tf | no |
| admin_key_permissions | Admin key permissions | `list(string)` | See variables.tf | no |
| admin_certificate_permissions | Admin certificate permissions | `list(string)` | See variables.tf | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | ID of the Key Vault |
| key_vault_name | Name of the Key Vault |
| key_vault_uri | URI of the Key Vault |
| mlflow_db_secret_id | ID of the MLflow database secret |
| storage_connection_secret_id | ID of the storage connection secret |
| acr_admin_username_secret_id | ID of the ACR username secret |
| acr_admin_password_secret_id | ID of the ACR password secret |
| key_vault_private_endpoint_id | ID of the private endpoint |

## Security Features

- **Soft Delete Protection**: 90-day retention for deleted secrets
- **Purge Protection**: Prevents permanent deletion of Key Vault
- **Network Access Control**: Configurable IP and subnet restrictions
- **RBAC Integration**: Azure AD-based access control
- **Private Endpoints**: Optional private connectivity
- **Audit Logging**: Comprehensive access and operation logging
- **Compliance**: SOC, FIPS 140-2 Level 2, Common Criteria compliance

## Access Control Models

### Least Privilege Access

- AKS clusters receive minimal required permissions
- User accounts have full administrative access
- Service principals have task-specific permissions

### Network Security

- Default deny for network access
- Explicit allow for trusted subnets
- Private endpoint support for air-gapped environments

## Compliance Features

- **Data Encryption**: All data encrypted at rest and in transit
- **Key Management**: Hardware Security Module (HSM) backed keys
- **Access Auditing**: Detailed logging of all operations
- **Compliance Certifications**: Multiple industry standards

## Best Practices

1. **Use managed identities** instead of service principals where possible
2. **Implement network restrictions** to limit access
3. **Enable private endpoints** for production environments
4. **Regular secret rotation** for enhanced security
5. **Monitor access patterns** and set up alerts
6. **Use Azure RBAC** for fine-grained permissions
7. **Enable diagnostic logging** for audit trails
8. **Implement secret versioning** for rollback capabilities
9. **Use Key Vault references** in application configurations
10. **Regular compliance reviews** and access audits
