# MLOps Platform - Modular Variables
# Production-ready configuration variables

# Core Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "mlops-platform-rg"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project    = "mlops-platform"
    Owner      = "Platform-Engineering"
    CostCenter = "ML-Platform"
    ManagedBy  = "Terraform"
  }
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28.0"

  validation {
    condition     = can(regex("^1\\.(2[7-9]|[3-9][0-9])\\.", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.27 or higher."
  }
}

variable "system_node_pool_config" {
  description = "Configuration for system node pool"
  type = object({
    node_count          = number
    vm_size             = string
    max_pods            = number
    availability_zones  = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
  })
  default = {
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
  }
}

variable "gpu_node_pool_config" {
  description = "Configuration for GPU node pool"
  type = object({
    vm_size             = string
    max_pods            = number
    availability_zones  = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_taints         = list(string)
  })
  default = {
    vm_size             = "Standard_NC6s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 0
    max_count           = 5
    node_taints         = ["workload=ml-training:NoSchedule"]
  }
}

variable "compute_node_pool_config" {
  description = "Configuration for compute node pool"
  type = object({
    vm_size             = string
    max_pods            = number
    availability_zones  = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
  })
  default = {
    vm_size             = "Standard_D8s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 20
  }
}

variable "enable_gpu_node_pool" {
  description = "Enable GPU node pool for ML training"
  type        = bool
  default     = true
}

variable "enable_compute_node_pool" {
  description = "Enable general compute node pool"
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "Enable private AKS cluster"
  type        = bool
  default     = false
}

variable "aks_admin_group_object_ids" {
  description = "Object IDs of Azure AD groups for AKS admin access"
  type        = list(string)
  default     = []
}

# Storage Configuration
variable "acr_geo_replications" {
  description = "Geo-replication configuration for Azure Container Registry"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = [
    {
      location                = "West US 2"
      zone_redundancy_enabled = true
    }
  ]
}

# Network Configuration
variable "enable_private_endpoints" {
  description = "Enable private endpoints for Azure services"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 30 and 730."
  }
}

variable "log_daily_quota_gb" {
  description = "Daily quota for logs in GB"
  type        = number
  default     = 10
}

variable "enable_monitoring_alerts" {
  description = "Enable monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_email_receivers" {
  description = "Email addresses for monitoring alerts"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = [
    {
      name          = "MLOps Team"
      email_address = "mlops-team@lucidtherapeutics.com"
    }
  ]
}

# Security Configuration
variable "enable_security_center" {
  description = "Enable Azure Security Center"
  type        = bool
  default     = true
}

variable "security_contact_email" {
  description = "Security contact email for Azure Security Center"
  type        = string
  default     = "security@lucidtherapeutics.com"
}

# Feature Flags
variable "enable_advanced_networking" {
  description = "Enable advanced networking features"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity for AKS"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup for critical resources"
  type        = bool
  default     = true
}

# Cost Management
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 5000
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80

  validation {
    condition     = var.budget_alert_threshold > 0 && var.budget_alert_threshold <= 100
    error_message = "Budget alert threshold must be between 1 and 100."
  }
}
