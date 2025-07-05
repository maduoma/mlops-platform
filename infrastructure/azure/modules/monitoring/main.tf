# Azure Monitoring Module - Production MLOps Platform
# Handles Log Analytics, Application Insights, and monitoring configuration

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  tags = var.tags
}

# Application Insights for MLOps applications
resource "azurerm_application_insights" "main" {
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_type

  tags = var.tags
}

# Log Analytics solutions for container monitoring
resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "Containers"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }

  tags = var.tags
}

# Security Center contact
resource "azurerm_security_center_contact" "main" {
  count = var.enable_security_center ? 1 : 0

  name  = "${var.log_analytics_name}-security-contact"
  email = var.security_contact_email
  phone = var.security_contact_phone

  alert_notifications = true
  alerts_to_admins    = true
}

# Diagnostic settings for activity logs
resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  count = var.enable_activity_log_diagnostics ? 1 : 0

  name                       = "${var.log_analytics_name}-activity-logs"
  target_resource_id         = var.subscription_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.alert_webhook_receivers
    content {
      name        = webhook_receiver.value.name
      service_uri = webhook_receiver.value.service_uri
    }
  }

  tags = var.tags
}

# Metric alerts for critical MLOps metrics
resource "azurerm_monitor_metric_alert" "cpu_usage" {
  count = var.enable_metric_alerts ? 1 : 0

  name                = "${var.log_analytics_name}-cpu-usage-alert"
  resource_group_name = var.resource_group_name
  scopes              = var.alert_scopes
  description         = "Alert when CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Memory usage alert
resource "azurerm_monitor_metric_alert" "memory_usage" {
  count = var.enable_metric_alerts ? 1 : 0

  name                = "${var.log_analytics_name}-memory-usage-alert"
  resource_group_name = var.resource_group_name
  scopes              = var.alert_scopes
  description         = "Alert when memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "memory_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.memory_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}
