# Azure Kubernetes Service Module - Production MLOps Platform
# Handles AKS cluster, node pools, and Kubernetes-specific configuration

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # System node pool (required)
  default_node_pool {
    name           = var.system_node_pool.name
    node_count     = var.system_node_pool.node_count
    vm_size        = var.system_node_pool.vm_size
    vnet_subnet_id = var.subnet_id
    max_pods       = var.system_node_pool.max_pods
    zones          = var.system_node_pool.availability_zones

    auto_scaling_enabled = var.system_node_pool.enable_auto_scaling
    min_count            = var.system_node_pool.min_count
    max_count            = var.system_node_pool.max_count

    type = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "10%"
    }

    tags = merge(var.tags, {
      NodePool = "system"
      Role     = "system"
    })
  }

  # Managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network configuration
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    outbound_type     = "loadBalancer"
    load_balancer_sku = "standard"
  }

  # Enable Azure Policy
  azure_policy_enabled = var.azure_policy_enabled

  # Enable monitoring
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # RBAC and security
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Security and compliance
  private_cluster_enabled = var.private_cluster_enabled

  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# ML Training node pool with GPU support
resource "azurerm_kubernetes_cluster_node_pool" "ml_training" {
  count = var.enable_gpu_node_pool ? 1 : 0

  name                  = var.gpu_node_pool.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.gpu_node_pool.vm_size
  vnet_subnet_id        = var.subnet_id
  zones                 = var.gpu_node_pool.availability_zones

  auto_scaling_enabled = var.gpu_node_pool.enable_auto_scaling
  min_count            = var.gpu_node_pool.min_count
  max_count            = var.gpu_node_pool.max_count

  max_pods = var.gpu_node_pool.max_pods

  # Taints for ML workloads
  node_taints = var.gpu_node_pool.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = merge(var.tags, {
    NodePool = "ml-training"
    Role     = "gpu"
    GPU      = "enabled"
  })
}

# General compute node pool
resource "azurerm_kubernetes_cluster_node_pool" "compute" {
  count = var.enable_compute_node_pool ? 1 : 0

  name                  = var.compute_node_pool.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.compute_node_pool.vm_size
  vnet_subnet_id        = var.subnet_id
  zones                 = var.compute_node_pool.availability_zones

  auto_scaling_enabled = var.compute_node_pool.enable_auto_scaling
  min_count            = var.compute_node_pool.min_count
  max_count            = var.compute_node_pool.max_count

  max_pods = var.compute_node_pool.max_pods

  upgrade_settings {
    max_surge = "33%"
  }

  tags = merge(var.tags, {
    NodePool = "compute"
    Role     = "workload"
  })
}

# Container Registry integration
resource "azurerm_role_assignment" "acr_pull" {
  count = var.container_registry_id != "" ? 1 : 0

  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Storage integration
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count = var.storage_account_id != "" ? 1 : 0

  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
