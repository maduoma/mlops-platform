# Monitoring Module

This module creates comprehensive monitoring and observability infrastructure for the MLOps platform including Log Analytics, Application Insights, alerting, and security monitoring.

## Resources Created

- **Log Analytics Workspace**: Centralized logging and analytics
- **Application Insights**: Application performance monitoring
- **Container Monitoring**: AKS and container-specific monitoring
- **Action Groups**: Alert notification management
- **Metric Alerts**: Automated alerting for critical metrics
- **Security Center**: Optional security monitoring and compliance
- **Diagnostic Settings**: Activity log collection and analysis

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  log_analytics_name        = "mlops-logs-prod"
  application_insights_name = "mlops-ai-prod"
  resource_group_name       = "mlops-rg"
  location                  = "East US"
  
  # Monitoring configuration
  retention_in_days = 30
  daily_quota_gb    = 5
  
  # Alerting configuration
  action_group_name       = "mlops-alerts"
  action_group_short_name = "mlopsalert"
  alert_email_receivers = [
    {
      name          = "ops-team"
      email_address = "ops@company.com"
    }
  ]
  
  enable_metric_alerts = true
  alert_scopes        = [module.aks.cluster_id]
  
  # Security Center
  enable_security_center = true
  security_contact_email = "security@company.com"
  
  tags = {
    Environment = "production"
    Project     = "MLOps"
  }
}
```

## Monitoring Components

### Log Analytics Workspace

- **Purpose**: Central repository for all platform logs
- **Retention**: Configurable data retention (default: 30 days)
- **Daily Quota**: Cost control through data ingestion limits
- **Integrations**: AKS, Application Insights, Activity Logs

### Application Insights

- **Type**: Workspace-based Application Insights
- **Integration**: Connected to Log Analytics workspace
- **Features**: APM, distributed tracing, performance monitoring
- **Usage**: ML application and service monitoring

### Container Monitoring Solution

- **Solution**: Microsoft OMS Gallery Containers solution
- **Purpose**: Enhanced AKS and container monitoring
- **Metrics**: Node performance, pod health, container logs
- **Dashboards**: Pre-built visualizations for container workloads

## Alerting Framework

### Action Groups

Configurable notification channels:

- **Email Receivers**: Email notifications for alerts
- **Webhook Receivers**: Integration with external systems
- **SMS/Voice**: Additional notification methods (configurable)

### Metric Alerts

Pre-configured alerts for critical metrics:

1. **CPU Usage Alert**
   - **Threshold**: 80% average CPU utilization
   - **Window**: 15-minute evaluation period
   - **Frequency**: 5-minute checks
   - **Severity**: Warning (Level 2)

2. **Memory Usage Alert**
   - **Threshold**: 85% average memory utilization
   - **Window**: 15-minute evaluation period
   - **Frequency**: 5-minute checks
   - **Severity**: Warning (Level 2)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| log_analytics_name | Name of Log Analytics workspace | `string` | n/a | yes |
| application_insights_name | Name of Application Insights | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| log_analytics_sku | Log Analytics SKU | `string` | `"PerGB2018"` | no |
| retention_in_days | Log retention period | `number` | `30` | no |
| daily_quota_gb | Daily ingestion quota (GB) | `number` | `5` | no |
| application_type | Application Insights type | `string` | `"web"` | no |
| action_group_name | Name of action group | `string` | n/a | yes |
| action_group_short_name | Short name for action group | `string` | n/a | yes |
| alert_email_receivers | Email alert receivers | `list(object)` | `[]` | no |
| alert_webhook_receivers | Webhook alert receivers | `list(object)` | `[]` | no |
| enable_metric_alerts | Enable metric alerts | `bool` | `true` | no |
| alert_scopes | Resource IDs for alert scopes | `list(string)` | `[]` | no |
| cpu_alert_threshold | CPU usage alert threshold | `number` | `80` | no |
| memory_alert_threshold | Memory usage alert threshold | `number` | `85` | no |
| enable_security_center | Enable Security Center contact | `bool` | `false` | no |
| security_contact_email | Security contact email | `string` | `""` | no |
| security_contact_phone | Security contact phone | `string` | `""` | no |
| enable_activity_log_diagnostics | Enable activity log diagnostics | `bool` | `true` | no |
| subscription_id | Subscription ID for activity logs | `string` | `""` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| log_analytics_workspace_id | Log Analytics workspace ID |
| log_analytics_workspace_name | Log Analytics workspace name |
| log_analytics_workspace_primary_shared_key | Primary shared key (sensitive) |
| log_analytics_workspace_workspace_id | Workspace customer ID |
| application_insights_id | Application Insights ID |
| application_insights_name | Application Insights name |
| application_insights_instrumentation_key | Instrumentation key (sensitive) |
| application_insights_connection_string | Connection string (sensitive) |
| action_group_id | Action group ID |
| action_group_name | Action group name |
| cpu_alert_id | CPU alert ID |
| memory_alert_id | Memory alert ID |

## Monitoring Dashboards

### Pre-built Dashboards

1. **Container Performance**: Node and pod performance metrics
2. **Application Performance**: Response times, error rates, dependencies
3. **Infrastructure Health**: Resource utilization and availability
4. **Security Events**: Security-related alerts and events

### Custom KPIs for MLOps

- **Model Training Time**: Track training job duration
- **Inference Latency**: Monitor model serving response times
- **Data Pipeline Health**: Monitor ETL and data processing jobs
- **Resource Utilization**: Track GPU/CPU usage for ML workloads

## Cost Management

### Optimization Features

- **Daily Quota**: Control ingestion costs
- **Data Retention**: Balance compliance and cost
- **Sampling**: Reduce data volume for high-traffic applications
- **Export Options**: Archive data to cheaper storage

### Cost Monitoring

- **Usage Analytics**: Track data ingestion by source
- **Cost Alerts**: Notifications for budget thresholds
- **Optimization Recommendations**: Automated cost-saving suggestions

## Security and Compliance

### Data Protection

- **Encryption**: All data encrypted at rest and in transit
- **Access Control**: RBAC for workspace access
- **Data Residency**: Configurable data location
- **Audit Trails**: Comprehensive access logging

### Compliance Features

- **Data Retention Policies**: Configurable retention periods
- **Data Export**: Support for compliance reporting
- **Privacy Controls**: Data anonymization capabilities
- **Regulatory Standards**: SOC, ISO, GDPR compliance

## Best Practices

1. **Right-size retention periods** based on compliance requirements
2. **Use daily quotas** to control costs in non-production environments
3. **Configure meaningful alerts** with appropriate thresholds
4. **Leverage custom metrics** for ML-specific monitoring
5. **Implement dashboard governance** for consistent visualization
6. **Regular review of alert rules** to reduce noise
7. **Use sampling for high-volume applications** to control costs
8. **Set up automated responses** for critical alerts
9. **Monitor monitoring costs** regularly
10. **Implement log correlation** across different services
