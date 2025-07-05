# Azure Storage Module - Production MLOps Platform
# Handles storage accounts, containers, and MLflow artifact storage

# Storage Account for MLflow artifacts
resource "azurerm_storage_account" "mlflow" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"

  # Security settings
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  # Network rules
  network_rules {
    default_action             = var.network_rules.default_action
    bypass                     = var.network_rules.bypass
    virtual_network_subnet_ids = var.network_rules.subnet_ids
  }

  # Blob properties
  blob_properties {
    versioning_enabled            = var.blob_versioning_enabled
    change_feed_enabled           = var.blob_change_feed_enabled
    change_feed_retention_in_days = var.blob_change_feed_retention_days

    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }

  # Enable advanced threat protection
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Storage container for MLflow artifacts
resource "azurerm_storage_container" "mlflow_artifacts" {
  name                  = var.mlflow_container_name
  storage_account_id    = azurerm_storage_account.mlflow.id
  container_access_type = "private"
}

# Storage container for model registry
resource "azurerm_storage_container" "model_registry" {
  name                  = var.model_registry_container_name
  storage_account_id    = azurerm_storage_account.mlflow.id
  container_access_type = "private"
}

# Storage container for datasets
resource "azurerm_storage_container" "datasets" {
  name                  = var.datasets_container_name
  storage_account_id    = azurerm_storage_account.mlflow.id
  container_access_type = "private"
}

# Container Registry for container images
resource "azurerm_container_registry" "main" {
  name                = var.container_registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.container_registry_sku
  admin_enabled       = false

  # Network access rules
  network_rule_set {
    default_action = var.acr_network_rule_set.default_action

    dynamic "virtual_network" {
      for_each = var.acr_network_rule_set.virtual_networks
      content {
        action    = virtual_network.value.action
        subnet_id = virtual_network.value.subnet_id
      }
    }
  }

  # Geo-replication for high availability
  dynamic "georeplications" {
    for_each = var.container_registry_geo_replications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = var.tags
    }
  }

  # Enable content trust and vulnerability scanning
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Private endpoints for storage account (optional)
resource "azurerm_private_endpoint" "storage_blob" {
  count = var.enable_private_endpoints ? 1 : 0

  name                = "${azurerm_storage_account.mlflow.name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_storage_account.mlflow.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.mlflow.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private endpoints for container registry (optional)
resource "azurerm_private_endpoint" "acr" {
  count = var.enable_private_endpoints ? 1 : 0

  name                = "${azurerm_container_registry.main.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_container_registry.main.name}-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = var.tags
}
