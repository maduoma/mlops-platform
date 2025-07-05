# Storage Module Variables
variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "network_rules" {
  description = "Network access rules for storage account"
  type = object({
    default_action = string
    bypass         = list(string)
    subnet_ids     = list(string)
  })
  default = {
    default_action = "Allow"
    bypass         = ["AzureServices"]
    subnet_ids     = []
  }
}

variable "blob_versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "blob_change_feed_enabled" {
  description = "Enable blob change feed"
  type        = bool
  default     = true
}

variable "blob_change_feed_retention_days" {
  description = "Retention days for blob change feed"
  type        = number
  default     = 90
}

variable "blob_soft_delete_retention_days" {
  description = "Retention days for blob soft delete"
  type        = number
  default     = 30
}

variable "container_soft_delete_retention_days" {
  description = "Retention days for container soft delete"
  type        = number
  default     = 30
}

variable "mlflow_container_name" {
  description = "Name of the MLflow artifacts container"
  type        = string
  default     = "mlflow-artifacts"
}

variable "model_registry_container_name" {
  description = "Name of the model registry container"
  type        = string
  default     = "model-registry"
}

variable "datasets_container_name" {
  description = "Name of the datasets container"
  type        = string
  default     = "datasets"
}

variable "container_registry_name" {
  description = "Name of the container registry"
  type        = string
}

variable "container_registry_sku" {
  description = "SKU for the container registry"
  type        = string
  default     = "Premium"
}

variable "container_registry_geo_replications" {
  description = "Geo-replication configuration for container registry"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = []
}

variable "acr_network_rule_set" {
  description = "Network rule set for container registry"
  type = object({
    default_action = string
    virtual_networks = list(object({
      action    = string
      subnet_id = string
    }))
  })
  default = {
    default_action   = "Allow"
    virtual_networks = []
  }
}

variable "acr_trust_policy_enabled" {
  description = "Enable trust policy for container registry"
  type        = bool
  default     = true
}

variable "acr_retention_enabled" {
  description = "Enable retention policy for container registry"
  type        = bool
  default     = true
}

variable "acr_retention_days" {
  description = "Retention days for container registry"
  type        = number
  default     = 30
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for storage and ACR"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
