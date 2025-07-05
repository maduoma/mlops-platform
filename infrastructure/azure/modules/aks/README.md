# AKS Module

This module creates a production-ready Azure Kubernetes Service (AKS) cluster with multiple node pools optimized for MLOps workloads.

## Resources Created

- **AKS Cluster**: Managed Kubernetes cluster with RBAC enabled
- **System Node Pool**: Dedicated nodes for system workloads
- **GPU Node Pool**: Optional GPU-enabled nodes for ML training
- **Compute Node Pool**: General compute nodes for ML inference
- **Role Assignments**: Integration with ACR and storage
- **Monitoring Integration**: Container insights and logging

## Usage

```hcl
module "aks" {
  source = "./modules/aks"
  
  cluster_name        = "mlops-aks"
  location            = "East US"
  resource_group_name = "mlops-rg"
  dns_prefix          = "mlopsaks"
  kubernetes_version  = "1.27.7"
  
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  
  system_node_pool = {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 5
  }
  
  enable_gpu_node_pool     = true
  enable_compute_node_pool = true
  private_cluster_enabled  = false
  
  admin_group_object_ids = ["group-id-1", "group-id-2"]
  container_registry_id  = module.storage.container_registry_id
  storage_account_id     = module.storage.storage_account_id
  
  tags = {
    Environment = "production"
    Project     = "MLOps"
  }
}
```

## Node Pool Types

### System Node Pool

- **Purpose**: Runs system pods (CoreDNS, metrics-server, etc.)
- **VM Size**: Standard_D4s_v3 (4 vCPU, 16 GB RAM)
- **Scaling**: Auto-scaling enabled (1-5 nodes)
- **Taints**: None (accepts system and user workloads)

### GPU Node Pool (Optional)

- **Purpose**: ML training workloads requiring GPU acceleration
- **VM Size**: Standard_NC6s_v3 (6 vCPU, 112 GB RAM, 1 V100 GPU)
- **Scaling**: Auto-scaling enabled (0-10 nodes)
- **Taints**: `sku=gpu:NoSchedule` (dedicated for GPU workloads)

### Compute Node Pool (Optional)

- **Purpose**: CPU-intensive ML inference and batch processing
- **VM Size**: Standard_D8s_v3 (8 vCPU, 32 GB RAM)
- **Scaling**: Auto-scaling enabled (1-20 nodes)
- **Taints**: None (general compute workloads)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the AKS cluster | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| dns_prefix | DNS prefix for the cluster | `string` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `"1.27.7"` | no |
| subnet_id | Subnet ID for the cluster | `string` | n/a | yes |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | n/a | yes |
| system_node_pool | System node pool configuration | `object` | See variables.tf | no |
| gpu_node_pool | GPU node pool configuration | `object` | See variables.tf | no |
| compute_node_pool | Compute node pool configuration | `object` | See variables.tf | no |
| enable_gpu_node_pool | Enable GPU node pool | `bool` | `false` | no |
| enable_compute_node_pool | Enable compute node pool | `bool` | `true` | no |
| private_cluster_enabled | Enable private cluster | `bool` | `false` | no |
| admin_group_object_ids | Azure AD group IDs for cluster admins | `list(string)` | `[]` | no |
| container_registry_id | Container registry ID for integration | `string` | `""` | no |
| storage_account_id | Storage account ID for integration | `string` | `""` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the AKS cluster |
| cluster_name | Name of the AKS cluster |
| cluster_fqdn | FQDN of the AKS cluster |
| cluster_endpoint | Endpoint of the AKS cluster |
| cluster_identity | Managed identity of the cluster |
| kubeconfig | Kubeconfig for cluster access |
| node_resource_group | Resource group containing cluster nodes |

## Security Features

- **RBAC Integration**: Azure AD integration for authentication
- **Network Policies**: Calico network policies for pod-to-pod security
- **Private Cluster Support**: Optional private API server endpoint
- **Managed Identity**: System-assigned managed identity for Azure integrations
- **Role-Based Access**: Minimal required permissions for integrations

## Monitoring and Logging

- **Container Insights**: Integrated monitoring for containers and nodes
- **Log Analytics**: Centralized logging for cluster activities
- **Metrics Collection**: Performance metrics for all node pools
- **Alert Integration**: Ready for custom alert rules

## Best Practices

1. **Use separate node pools** for different workload types
2. **Enable auto-scaling** to optimize costs and performance
3. **Configure resource quotas** to prevent resource exhaustion
4. **Use availability zones** for high availability
5. **Implement proper RBAC** with Azure AD integration
6. **Regular updates** of Kubernetes version and node images
7. **Monitor resource utilization** and adjust node pool sizes accordingly
