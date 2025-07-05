# MLOps Platform - Modular Terraform Infrastructure

This directory contains the modular Terraform infrastructure for deploying a production-ready MLOps platform on Azure. The infrastructure is organized into reusable modules following Terraform best practices.

## Architecture Overview

The infrastructure consists of five main modules:

1. **Networking**: VNet, subnets, NSGs, and network security
2. **AKS**: Kubernetes cluster with multiple node pools for different workloads
3. **Storage**: Azure Storage Account and Container Registry for artifacts and images
4. **Security**: Key Vault, secrets management, and access policies
5. **Monitoring**: Log Analytics, Application Insights, and alerting

## Quick Start

### Prerequisites

- Terraform >= 1.0
- Azure CLI >= 2.30.0
- Valid Azure subscription with contributor access
- Azure Storage Account for Terraform state (configured in backend)

### Deployment

1. **Clone the repository and navigate to infrastructure directory**:

   ```bash
   git clone <repository-url>
   cd mlops-platform-demo/infrastructure/azure
   ```

2. **Configure variables**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**:

   ```bash
   terraform init
   ```

4. **Plan deployment**:

   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

5. **Deploy infrastructure**:

   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## Module Structure

```plaintext
infrastructure/azure/
├── main-modular.tf              # Main infrastructure configuration
├── variables-modular.tf         # Variable definitions
├── terraform.tfvars.example    # Example variables file
├── outputs.tf                   # Infrastructure outputs
└── modules/
    ├── networking/
    │   ├── main.tf             # Network resources
    │   ├── variables.tf        # Network variables
    │   ├── outputs.tf          # Network outputs
    │   └── README.md           # Network documentation
    ├── aks/
    │   ├── main.tf             # AKS cluster resources
    │   ├── variables.tf        # AKS variables
    │   ├── outputs.tf          # AKS outputs
    │   └── README.md           # AKS documentation
    ├── storage/
    │   ├── main.tf             # Storage resources
    │   ├── variables.tf        # Storage variables
    │   ├── outputs.tf          # Storage outputs
    │   └── README.md           # Storage documentation
    ├── security/
    │   ├── main.tf             # Security resources
    │   ├── variables.tf        # Security variables
    │   ├── outputs.tf          # Security outputs
    │   └── README.md           # Security documentation
    └── monitoring/
        ├── main.tf             # Monitoring resources
        ├── variables.tf        # Monitoring variables
        ├── outputs.tf          # Monitoring outputs
        └── README.md           # Monitoring documentation
```

## Resource Naming Convention

Resources follow a consistent naming pattern:

- **Format**: `{project-name}-{resource-type}-{environment}`
- **Example**: `lucid-mlops-cluster-prod`
- **Storage**: Special handling for globally unique names (no hyphens)

## Configuration Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `resource_group_name` | Resource group name | `string` |
| `location` | Azure region | `string` |
| `environment` | Environment name (dev/staging/prod) | `string` |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| `kubernetes_version` | Kubernetes version | `"1.27.7"` |
| `enable_gpu_node_pool` | Enable GPU nodes | `false` |
| `enable_private_endpoints` | Enable private endpoints | `false` |
| `enable_monitoring_alerts` | Enable metric alerts | `true` |
| `log_retention_days` | Log retention period | `30` |

### Example terraform.tfvars

```hcl
# Basic Configuration
resource_group_name = "mlops-platform-prod"
location           = "East US"
environment        = "prod"

# Kubernetes Configuration
kubernetes_version     = "1.27.7"
enable_gpu_node_pool  = true
enable_compute_node_pool = true

# Security Configuration
enable_private_endpoints = true
enable_security_center  = true
security_contact_email  = "security@company.com"

# Monitoring Configuration
enable_monitoring_alerts = true
log_retention_days      = 90
log_daily_quota_gb      = 10

alert_email_receivers = [
  {
    name          = "ops-team"
    email_address = "ops@company.com"
  },
  {
    name          = "dev-team"  
    email_address = "dev@company.com"
  }
]

# AKS Admin Groups
aks_admin_group_object_ids = [
  "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
  "ffffffff-gggg-hhhh-iiii-jjjjjjjjjjjj"
]

# Node Pool Configuration
system_node_pool_config = {
  node_count         = 3
  vm_size           = "Standard_D4s_v3"
  enable_auto_scaling = true
  min_count         = 1
  max_count         = 5
  availability_zones = ["1", "2", "3"]
}

gpu_node_pool_config = {
  vm_size           = "Standard_NC6s_v3"
  enable_auto_scaling = true
  min_count         = 0
  max_count         = 10
  availability_zones = ["1", "2", "3"]
}

# Tags
common_tags = {
  Project     = "MLOps-Platform"
  Environment = "Production"
  Owner       = "Platform-Engineering"
  CostCenter  = "Engineering"
}
```

## Deployment Environments

### Development

- **Purpose**: Development and testing
- **Features**: Basic monitoring, no private endpoints
- **Cost**: Optimized for development workloads
- **Node Pools**: System only, smaller VM sizes

### Staging

- **Purpose**: Pre-production testing
- **Features**: Full monitoring, private endpoints optional
- **Cost**: Balanced performance and cost
- **Node Pools**: System + Compute, production-like configuration

### Production

- **Purpose**: Production workloads
- **Features**: Full security, monitoring, and redundancy
- **Cost**: Performance-optimized
- **Node Pools**: System + Compute + GPU (optional)

## Security Features

### Network Security

- **Private Cluster**: Optional private AKS API server
- **Network Policies**: Calico for pod-to-pod security
- **Private Endpoints**: Private connectivity for storage and Key Vault
- **NSG Rules**: Restrictive network security groups

### Identity and Access

- **Managed Identity**: System-assigned identities for Azure integrations
- **RBAC**: Azure AD integration for AKS access
- **Key Vault**: Centralized secrets management
- **Least Privilege**: Minimal required permissions

### Data Protection

- **Encryption**: All data encrypted at rest and in transit
- **Backup**: Automated backup for critical data
- **Versioning**: Blob versioning for data protection
- **Soft Delete**: Protection against accidental deletions

## Monitoring and Observability

### Metrics and Logs

- **Container Insights**: AKS cluster and node monitoring
- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging and analytics
- **Custom Metrics**: ML-specific monitoring capabilities

### Alerting

- **Metric Alerts**: CPU, memory, and custom thresholds
- **Action Groups**: Email, SMS, webhook notifications
- **Security Alerts**: Security Center integration
- **Cost Alerts**: Budget and spending notifications

## Cost Optimization

### Resource Optimization

- **Auto-scaling**: Dynamic scaling based on demand
- **Spot Instances**: Optional for non-critical workloads
- **Reserved Instances**: Long-term commitment discounts
- **Right-sizing**: Appropriate VM sizes for workloads

### Monitoring and Control

- **Daily Quotas**: Log ingestion cost control
- **Resource Tagging**: Cost allocation and tracking
- **Budget Alerts**: Proactive cost notifications
- **Usage Analytics**: Resource utilization insights

## Troubleshooting

### Common Issues

1. **Terraform Backend Error**

   ```bash
   # Ensure backend storage account exists
   az storage account show --name <storage-account> --resource-group <rg>
   ```

2. **AKS Cluster Access**

   ```bash
   # Get AKS credentials
   az aks get-credentials --resource-group <rg> --name <cluster-name>
   ```

3. **Private Endpoint DNS Resolution**

   ```bash
   # Check private DNS zone configuration
   az network private-dns zone list --resource-group <rg>
   ```

### Debug Commands

```bash
# Check Terraform state
terraform state list

# Validate configuration
terraform validate

# Plan with debug output
TF_LOG=DEBUG terraform plan

# Check AKS cluster status
kubectl cluster-info

# Verify node pools
kubectl get nodes -o wide
```

## Maintenance

### Regular Tasks

- **Kubernetes Updates**: Monthly version updates
- **Security Patches**: Automatic node image updates
- **Certificate Rotation**: Automatic certificate management
- **Backup Verification**: Regular backup restore testing

### Monitoring Health

- **Dashboard Reviews**: Weekly dashboard analysis
- **Alert Tuning**: Monthly alert threshold adjustments
- **Cost Reviews**: Monthly cost optimization reviews
- **Security Scans**: Weekly security assessments

## Contributing

1. **Module Development**: Follow Terraform module best practices
2. **Testing**: Use Terratest for automated testing
3. **Documentation**: Update README files for changes
4. **Versioning**: Use semantic versioning for modules
5. **Code Review**: Peer review for all changes

## Support

For support and questions:

- **Documentation**: Check module-specific README files
- **Issues**: Create GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub discussions for questions
- **Security**: Report security issues privately

## License

This project is licensed under the MIT License - see the LICENSE file for details.
