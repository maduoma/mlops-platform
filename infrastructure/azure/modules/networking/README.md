# Networking Module

This module creates the core networking infrastructure for the MLOps platform including VNet, subnets, and network security groups.

## Resources Created

- **Virtual Network**: Main VNet with configurable address space
- **AKS Subnet**: Dedicated subnet for AKS cluster nodes
- **Private Endpoints Subnet**: Subnet for private endpoints
- **Network Security Groups**: Security rules for each subnet
- **Route Table**: Custom routing for AKS subnet

## Usage

```hcl
module "networking" {
  source = "./modules/networking"
  
  vnet_name                                 = "mlops-vnet"
  location                                  = "East US"
  resource_group_name                       = "mlops-rg"
  vnet_address_space                        = ["10.0.0.0/16"]
  aks_subnet_address_prefixes               = ["10.0.1.0/24"]
  private_endpoints_subnet_address_prefixes = ["10.0.2.0/24"]
  
  tags = {
    Environment = "production"
    Project     = "MLOps"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| vnet_address_space | Address space for VNet | `list(string)` | n/a | yes |
| aks_subnet_address_prefixes | AKS subnet CIDR blocks | `list(string)` | n/a | yes |
| private_endpoints_subnet_address_prefixes | Private endpoints subnet CIDR blocks | `list(string)` | n/a | yes |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | ID of the virtual network |
| vnet_name | Name of the virtual network |
| aks_subnet_id | ID of the AKS subnet |
| private_endpoints_subnet_id | ID of the private endpoints subnet |
| aks_nsg_id | ID of the AKS network security group |
| private_endpoints_nsg_id | ID of the private endpoints network security group |

## Security Features

- **Network Segmentation**: Separate subnets for different workloads
- **Network Security Groups**: Restrictive rules by default
- **Private Endpoints Support**: Dedicated subnet for private connectivity
- **Custom Routing**: Route table configuration for AKS integration

## Best Practices

1. Use non-overlapping CIDR blocks
2. Plan subnet sizes for future growth
3. Follow the principle of least privilege for NSG rules
4. Use consistent naming conventions
5. Apply appropriate tags for resource management
