# MLOps Platform - Modular Terraform Infrastructure
# Production-ready Azure infrastructure using best practices

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.common_tags
}

# Common locals
locals {
  # Naming convention - using consistent kebab-case
  project_name = "mlops-platform"
  environment  = var.environment

  # Common tags - centralized tag management
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = local.project_name
    Owner       = "Platform-Engineering"
    ManagedBy   = "Terraform"
  })

  # Network configuration
  vnet_address_space = ["10.0.0.0/16"]
  aks_subnet_cidrs   = ["10.0.1.0/24"]
  pe_subnet_cidrs    = ["10.0.2.0/24"]

  # Resource naming - consistent naming pattern
  vnet_name            = "${local.project_name}-vnet-${local.environment}"
  aks_cluster_name     = "${local.project_name}-aks-${local.environment}"
  storage_account_name = replace("${local.project_name}str${local.environment}", "-", "")
  acr_name             = replace("${local.project_name}acr${local.environment}", "-", "")
  key_vault_name       = "${local.project_name}-kv-${local.environment}"
  log_analytics_name   = "${local.project_name}-logs-${local.environment}"
  app_insights_name    = "${local.project_name}-ai-${local.environment}"
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  vnet_name                                 = local.vnet_name
  location                                  = azurerm_resource_group.main.location
  resource_group_name                       = azurerm_resource_group.main.name
  vnet_address_space                        = local.vnet_address_space
  aks_subnet_address_prefixes               = local.aks_subnet_cidrs
  private_endpoints_subnet_address_prefixes = local.pe_subnet_cidrs

  tags = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  storage_account_name    = local.storage_account_name
  container_registry_name = local.acr_name
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location

  # Network configuration
  network_rules = {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
    subnet_ids     = var.enable_private_endpoints ? [module.networking.aks_subnet_id] : []
  }

  # ACR network rules
  acr_network_rule_set = {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    virtual_networks = var.enable_private_endpoints ? [
      {
        action    = "Allow"
        subnet_id = module.networking.aks_subnet_id
      }
    ] : []
  }

  # Geo-replication for ACR
  container_registry_geo_replications = var.acr_geo_replications

  # Private endpoints
  enable_private_endpoints   = var.enable_private_endpoints
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id

  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  log_analytics_name        = local.log_analytics_name
  application_insights_name = local.app_insights_name
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location

  # Monitoring configuration
  retention_in_days = var.log_retention_days
  daily_quota_gb    = var.log_daily_quota_gb

  # Alerting configuration
  action_group_name       = "${local.project_name}-alerts"
  action_group_short_name = "mlopsalert"
  alert_email_receivers   = var.alert_email_receivers
  enable_metric_alerts    = var.enable_monitoring_alerts
  alert_scopes            = [module.aks.cluster_id]

  # Security Center
  enable_security_center = var.enable_security_center
  security_contact_email = var.security_contact_email

  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  key_vault_name      = local.key_vault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Access policies
  aks_principal_id       = module.aks.cluster_identity[0].principal_id
  current_user_object_id = data.azurerm_client_config.current.object_id

  # Network configuration
  network_acls = {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = "AzureServices"
    subnet_ids     = var.enable_private_endpoints ? [module.networking.aks_subnet_id] : []
  }

  # Private endpoint
  enable_private_endpoint    = var.enable_private_endpoints
  private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id

  # Secrets (will be populated after deployment)
  storage_connection_string = module.storage.storage_connection_string

  tags = local.common_tags

  depends_on = [module.aks]
}

# AKS Module
module "aks" {
  source = "./modules/aks"

  cluster_name        = local.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = replace(local.project_name, "-", "")
  kubernetes_version  = var.kubernetes_version

  # Network configuration
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  # Node pool configuration
  system_node_pool = {
    name                = "system"
    node_count          = var.system_node_pool_config.node_count
    vm_size             = var.system_node_pool_config.vm_size
    max_pods            = var.system_node_pool_config.max_pods
    availability_zones  = var.system_node_pool_config.availability_zones
    enable_auto_scaling = var.system_node_pool_config.enable_auto_scaling
    min_count           = var.system_node_pool_config.min_count
    max_count           = var.system_node_pool_config.max_count
  }

  gpu_node_pool = {
    name                = "gpu"
    vm_size             = var.gpu_node_pool_config.vm_size
    max_pods            = var.gpu_node_pool_config.max_pods
    availability_zones  = var.gpu_node_pool_config.availability_zones
    enable_auto_scaling = var.gpu_node_pool_config.enable_auto_scaling
    min_count           = var.gpu_node_pool_config.min_count
    max_count           = var.gpu_node_pool_config.max_count
    node_taints         = var.gpu_node_pool_config.node_taints
  }

  compute_node_pool = {
    name                = "compute"
    vm_size             = var.compute_node_pool_config.vm_size
    max_pods            = var.compute_node_pool_config.max_pods
    availability_zones  = var.compute_node_pool_config.availability_zones
    enable_auto_scaling = var.compute_node_pool_config.enable_auto_scaling
    min_count           = var.compute_node_pool_config.min_count
    max_count           = var.compute_node_pool_config.max_count
  }

  # Feature flags
  enable_gpu_node_pool     = var.enable_gpu_node_pool
  enable_compute_node_pool = var.enable_compute_node_pool
  private_cluster_enabled  = var.private_cluster_enabled

  # RBAC configuration
  admin_group_object_ids = var.aks_admin_group_object_ids

  # Integration with other resources
  container_registry_id = module.storage.container_registry_id
  storage_account_id    = module.storage.storage_account_id

  tags = local.common_tags

  depends_on = [module.networking, module.monitoring]
}
