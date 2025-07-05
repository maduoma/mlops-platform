# Monitoring Module Variables
variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace"
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

variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention period in days"
  type        = number
  default     = 90
}

variable "daily_quota_gb" {
  description = "Daily quota in GB"
  type        = number
  default     = 10
}

variable "application_insights_name" {
  description = "Name of Application Insights"
  type        = string
}

variable "application_type" {
  description = "Application type for Application Insights"
  type        = string
  default     = "web"
}

variable "enable_security_center" {
  description = "Enable Security Center configuration"
  type        = bool
  default     = false
}

variable "security_contact_email" {
  description = "Security contact email"
  type        = string
  default     = ""
}

variable "security_contact_phone" {
  description = "Security contact phone"
  type        = string
  default     = ""
}

variable "enable_activity_log_diagnostics" {
  description = "Enable activity log diagnostics"
  type        = bool
  default     = true
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "action_group_name" {
  description = "Name of the action group"
  type        = string
}

variable "action_group_short_name" {
  description = "Short name for action group"
  type        = string
}

variable "alert_email_receivers" {
  description = "Email receivers for alerts"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "alert_webhook_receivers" {
  description = "Webhook receivers for alerts"
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

variable "enable_metric_alerts" {
  description = "Enable metric alerts"
  type        = bool
  default     = true
}

variable "alert_scopes" {
  description = "Scopes for metric alerts"
  type        = list(string)
  default     = []
}

variable "cpu_alert_threshold" {
  description = "CPU usage threshold for alerts"
  type        = number
  default     = 80
}

variable "memory_alert_threshold" {
  description = "Memory usage threshold for alerts"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
