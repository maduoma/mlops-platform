# Security Module Variables
variable "key_vault_name" {
  description = "Name of the Key Vault"
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

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "premium"
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain deleted secrets"
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network access rules for Key Vault"
  type = object({
    default_action = string
    bypass         = string
    subnet_ids     = list(string)
  })
  default = {
    default_action = "Allow"
    bypass         = "AzureServices"
    subnet_ids     = []
  }
}

variable "aks_principal_id" {
  description = "Principal ID of the AKS cluster"
  type        = string
  default     = ""
}

variable "aks_secret_permissions" {
  description = "Secret permissions for AKS cluster"
  type        = list(string)
  default     = ["Get", "List"]
}

variable "aks_key_permissions" {
  description = "Key permissions for AKS cluster"
  type        = list(string)
  default     = ["Get", "List"]
}

variable "current_user_object_id" {
  description = "Object ID of the current user/service principal"
  type        = string
  default     = ""
}

variable "admin_secret_permissions" {
  description = "Secret permissions for admin users"
  type        = list(string)
  default     = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
}

variable "admin_key_permissions" {
  description = "Key permissions for admin users"
  type        = list(string)
  default     = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"]
}

variable "admin_certificate_permissions" {
  description = "Certificate permissions for admin users"
  type        = list(string)
  default     = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"]
}

variable "mlflow_db_connection_string" {
  description = "MLflow database connection string"
  type        = string
  default     = ""
  sensitive   = true
}

variable "storage_connection_string" {
  description = "Storage account connection string"
  type        = string
  default     = ""
  sensitive   = true
}

variable "acr_admin_username" {
  description = "Container registry admin username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "acr_admin_password" {
  description = "Container registry admin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Key Vault"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
