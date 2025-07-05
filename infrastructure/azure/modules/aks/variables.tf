# AKS Module Variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.0"
}

variable "subnet_id" {
  description = "ID of the subnet for AKS"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "container_registry_id" {
  description = "ID of the Container Registry"
  type        = string
  default     = ""
}

variable "storage_account_id" {
  description = "ID of the Storage Account"
  type        = string
  default     = ""
}

variable "network_plugin" {
  description = "Network plugin for AKS"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "Service CIDR for AKS"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP for AKS"
  type        = string
  default     = "10.1.0.10"
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups that should have admin access"
  type        = list(string)
  default     = []
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

variable "system_node_pool" {
  description = "Configuration for system node pool"
  type = object({
    name                = string
    node_count          = number
    vm_size             = string
    max_pods            = number
    availability_zones  = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
  })
  default = {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
  }
}

variable "gpu_node_pool" {
  description = "Configuration for GPU node pool"
  type = object({
    name                = string
    vm_size             = string
    max_pods            = number
    availability_zones  = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_taints         = list(string)
  })
  default = {
    name                = "gpu"
    vm_size             = "Standard_NC6s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 0
    max_count           = 5
    node_taints         = ["workload=ml-training:NoSchedule"]
  }
}

variable "compute_node_pool" {
  description = "Configuration for compute node pool"
  type = object({
    name                = string
    vm_size             = string
    max_pods            = number
    availability_zones  = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
  })
  default = {
    name                = "compute"
    vm_size             = "Standard_D8s_v3"
    max_pods            = 110
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 20
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
