# Storage Module Outputs

# Storage Account
output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.mlflow.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.mlflow.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.mlflow.primary_access_key
  sensitive   = true
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.mlflow.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint for the storage account"
  value       = azurerm_storage_account.mlflow.primary_blob_endpoint
}

# Storage Containers
output "mlflow_container_name" {
  description = "Name of the MLflow artifacts container"
  value       = azurerm_storage_container.mlflow_artifacts.name
}

output "model_registry_container_name" {
  description = "Name of the model registry container"
  value       = azurerm_storage_container.model_registry.name
}

output "datasets_container_name" {
  description = "Name of the datasets container"
  value       = azurerm_storage_container.datasets.name
}

# Container Registry
output "container_registry_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server for the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = azurerm_container_registry.main.admin_username
}

output "container_registry_admin_password" {
  description = "Admin password for the container registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# Private Endpoints
output "storage_private_endpoint_id" {
  description = "ID of the storage private endpoint"
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.storage_blob[0].id : null
}

output "acr_private_endpoint_id" {
  description = "ID of the ACR private endpoint"
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.acr[0].id : null
}
