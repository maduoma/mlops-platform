# Azure Security Module - Production MLOps Platform
# Handles Key Vault, secrets, and security policies

# Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.key_vault_sku
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # Network access rules
  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    virtual_network_subnet_ids = var.network_acls.subnet_ids
  }

  tags = var.tags
}

# Access policy for AKS cluster
resource "azurerm_key_vault_access_policy" "aks_cluster" {
  count = var.aks_principal_id != "" ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.aks_principal_id

  secret_permissions = var.aks_secret_permissions
  key_permissions    = var.aks_key_permissions
}

# Access policy for current service principal/user
resource "azurerm_key_vault_access_policy" "current" {
  count = var.current_user_object_id != "" ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.current_user_object_id

  secret_permissions      = var.admin_secret_permissions
  key_permissions         = var.admin_key_permissions
  certificate_permissions = var.admin_certificate_permissions
}

# MLflow database connection string secret
resource "azurerm_key_vault_secret" "mlflow_db_connection" {
  count = var.mlflow_db_connection_string != "" ? 1 : 0

  name         = "mlflow-db-connection-string"
  value        = var.mlflow_db_connection_string
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Storage account connection string secret
resource "azurerm_key_vault_secret" "storage_connection" {
  count = var.storage_connection_string != "" ? 1 : 0

  name         = "storage-connection-string"
  value        = var.storage_connection_string
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Container registry admin credentials (if enabled)
resource "azurerm_key_vault_secret" "acr_admin_username" {
  count = var.acr_admin_username != "" ? 1 : 0

  name         = "acr-admin-username"
  value        = var.acr_admin_username
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.current]
}

resource "azurerm_key_vault_secret" "acr_admin_password" {
  count = var.acr_admin_password != "" ? 1 : 0

  name         = "acr-admin-password"
  value        = var.acr_admin_password
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.current]
}

# Private endpoint for Key Vault (optional)
resource "azurerm_private_endpoint" "key_vault" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${azurerm_key_vault.main.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_key_vault.main.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}
