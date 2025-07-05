# MLOps Platform - Terraform Backend Configuration
# Azure Storage backend for remote state management
# Note: This configuration is overridden by environment-specific backend configs

terraform {
  backend "azurerm" {
    # These values are overridden by environment-specific backend configuration files
    # See environments/dev.backend.conf, environments/staging.backend.conf, etc.
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "mlopsplatformstate"
    container_name       = "tfstate"
    key                  = "default.tfstate"
  }
}
