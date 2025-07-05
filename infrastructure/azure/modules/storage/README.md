# Storage Module

This module creates the storage infrastructure for the MLOps platform including Azure Storage Account, Container Registry, and related security configurations.

## Resources Created

- **Storage Account**: High-performance storage for MLflow artifacts and datasets
- **Storage Containers**: Organized storage for different data types
- **Container Registry**: Private Docker image registry
- **Private Endpoints**: Optional private connectivity for storage resources
- **Security Configurations**: Network rules and access controls

## Usage

```hcl
module "storage" {
  source = "./modules/storage"
  
  storage_account_name    = "mlopsstrg001"
  container_registry_name = "mlopsacr001"
  resource_group_name     = "mlops-rg"
  location                = "East US"
  
  network_rules = {
    default_action = "Allow"
    bypass         = ["AzureServices"]
    subnet_ids     = [module.networking.aks_subnet_id]
  }
  
  acr_network_rule_set = {
    default_action = "Allow"
    virtual_networks = [
      {
        action    = "Allow"
        subnet_id = module.networking.aks_subnet_id
      }
    ]
  }
  
  enable_private_endpoints   = false
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id
  
  tags = {
    Environment = "production"
    Project     = "MLOps"
  }
}
```

## Storage Containers

The module creates the following storage containers:

1. **MLflow Artifacts** (`mlflow-artifacts`): Stores ML experiment artifacts, models, and metadata
2. **Model Registry** (`model-registry`): Centralized model versioning and deployment artifacts
3. **Datasets** (`datasets`): Training and validation datasets for ML experiments

## Container Registry Features

- **SKU**: Premium tier for production workloads
- **Admin Access**: Disabled for security (uses managed identity)
- **Geo-replication**: Optional multi-region replication
- **Network Rules**: Configurable access restrictions
- **Content Trust**: Enhanced security for container images
- **Vulnerability Scanning**: Built-in security scanning

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| storage_account_name | Name of the storage account | `string` | n/a | yes |
| container_registry_name | Name of the container registry | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| account_tier | Storage account performance tier | `string` | `"Premium"` | no |
| replication_type | Storage replication type | `string` | `"LRS"` | no |
| mlflow_container_name | MLflow artifacts container name | `string` | `"mlflow-artifacts"` | no |
| model_registry_container_name | Model registry container name | `string` | `"model-registry"` | no |
| datasets_container_name | Datasets container name | `string` | `"datasets"` | no |
| container_registry_sku | Container registry SKU | `string` | `"Premium"` | no |
| network_rules | Storage account network rules | `object` | See variables.tf | no |
| acr_network_rule_set | ACR network rule set | `object` | See variables.tf | no |
| container_registry_geo_replications | Geo-replication settings | `list(object)` | `[]` | no |
| enable_private_endpoints | Enable private endpoints | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for private endpoints | `string` | `""` | no |
| blob_versioning_enabled | Enable blob versioning | `bool` | `true` | no |
| blob_change_feed_enabled | Enable blob change feed | `bool` | `true` | no |
| blob_soft_delete_retention_days | Blob soft delete retention | `number` | `30` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_id | ID of the storage account |
| storage_account_name | Name of the storage account |
| storage_account_primary_access_key | Primary access key (sensitive) |
| storage_account_primary_connection_string | Primary connection string (sensitive) |
| storage_account_primary_blob_endpoint | Primary blob endpoint |
| mlflow_container_name | MLflow artifacts container name |
| model_registry_container_name | Model registry container name |
| datasets_container_name | Datasets container name |
| container_registry_id | Container registry ID |
| container_registry_name | Container registry name |
| container_registry_login_server | Container registry login server |
| container_registry_admin_username | Admin username |
| container_registry_admin_password | Admin password (sensitive) |

## Security Features

- **Disabled Public Access**: Nested items cannot be public
- **Shared Access Keys**: Disabled for enhanced security
- **Network Access Rules**: Configurable IP and subnet restrictions
- **Private Endpoints**: Optional private connectivity
- **Blob Versioning**: Track changes to blob objects
- **Soft Delete**: Protection against accidental deletions
- **Change Feed**: Audit trail for blob operations
- **System-Assigned Identity**: Secure Azure service integration

## Performance Features

- **Premium Storage Tier**: High IOPS and low latency
- **Hot Access Tier**: Optimized for frequently accessed data
- **Geo-replication**: Optional for disaster recovery
- **Zone Redundancy**: Data protection within region

## Best Practices

1. **Use Premium storage** for production ML workloads
2. **Enable versioning and soft delete** for data protection
3. **Configure network rules** to restrict access
4. **Use private endpoints** for enhanced security
5. **Implement proper naming conventions** for containers
6. **Monitor storage metrics** and set up alerts
7. **Regular backup strategies** for critical data
8. **Use managed identities** instead of access keys
