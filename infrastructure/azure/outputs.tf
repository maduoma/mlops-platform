# MLOps Platform - Terraform Outputs
# Infrastructure outputs for external consumption and reference

# Resource Group outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Networking outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.networking.aks_subnet_id
}

output "private_endpoints_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = module.networking.private_endpoints_subnet_id
}

# AKS outputs
output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "aks_cluster_endpoint" {
  description = "Endpoint of the AKS cluster"
  value       = module.aks.cluster_endpoint
  sensitive   = true
}

output "aks_kubeconfig" {
  description = "Kubeconfig for the AKS cluster"
  value       = module.aks.kubeconfig
  sensitive   = true
}

output "aks_node_resource_group" {
  description = "Resource group containing AKS nodes"
  value       = module.aks.node_resource_group
}

# Storage outputs
output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = module.storage.storage_account_primary_blob_endpoint
}

output "mlflow_container_name" {
  description = "Name of the MLflow artifacts container"
  value       = module.storage.mlflow_container_name
}

output "model_registry_container_name" {
  description = "Name of the model registry container"
  value       = module.storage.model_registry_container_name
}

output "datasets_container_name" {
  description = "Name of the datasets container"
  value       = module.storage.datasets_container_name
}

# Container Registry outputs
output "container_registry_id" {
  description = "ID of the container registry"
  value       = module.storage.container_registry_id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = module.storage.container_registry_name
}

output "container_registry_login_server" {
  description = "Login server of the container registry"
  value       = module.storage.container_registry_login_server
}

# Security outputs
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.security.key_vault_id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.security.key_vault_uri
}

# Monitoring outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_name
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace customer ID for Log Analytics"
  value       = module.monitoring.log_analytics_workspace_workspace_id
}

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = module.monitoring.application_insights_id
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = module.monitoring.application_insights_name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

# Deployment information
output "deployment_environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "terraform_workspace" {
  description = "Terraform workspace used for deployment"
  value       = terraform.workspace
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
