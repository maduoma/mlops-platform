# Security Module Outputs

# Key Vault
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# Secrets
output "mlflow_db_secret_id" {
  description = "ID of the MLflow database connection string secret"
  value       = var.mlflow_db_connection_string != "" ? azurerm_key_vault_secret.mlflow_db_connection[0].id : null
}

output "storage_connection_secret_id" {
  description = "ID of the storage connection string secret"
  value       = var.storage_connection_string != "" ? azurerm_key_vault_secret.storage_connection[0].id : null
}

output "acr_admin_username_secret_id" {
  description = "ID of the ACR admin username secret"
  value       = var.acr_admin_username != "" ? azurerm_key_vault_secret.acr_admin_username[0].id : null
}

output "acr_admin_password_secret_id" {
  description = "ID of the ACR admin password secret"
  value       = var.acr_admin_password != "" ? azurerm_key_vault_secret.acr_admin_password[0].id : null
}

# Private Endpoint
output "key_vault_private_endpoint_id" {
  description = "ID of the Key Vault private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.key_vault[0].id : null
}
