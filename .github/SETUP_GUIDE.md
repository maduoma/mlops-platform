# GitHub Actions Setup Guide

This document explains how to configure GitHub repository secrets and variables required for the MLOps platform CI/CD workflows.

## Required GitHub Secrets

### Azure Authentication

- `AZURE_CREDENTIALS`: Azure service principal credentials JSON

  ```json
  {
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "subscriptionId": "your-subscription-id",
    "tenantId": "your-tenant-id"
  }
  ```

### Kubernetes Configuration

- `KUBECONFIG`: Base64-encoded kubeconfig file for AKS cluster access

  ```bash
  az aks get-credentials --resource-group mlops-platform-rg --name lucid-mlops-cluster
  cat ~/.kube/config | base64 -w 0
  ```

### MLflow Configuration

- `MLFLOW_TRACKING_URI`: MLflow tracking server URL

  ```text
  http://mlflow.lucid-mlops.com
  ```

### Terraform State Management

- `TERRAFORM_STATE_RG`: Resource group containing Terraform state storage

  ```text
  terraform-state-rg
  ```

- `TERRAFORM_STATE_STORAGE`: Storage account name for Terraform state

  ```text
  lucidmlopsstate
  ```

## Required GitHub Variables

### Infrastructure Configuration

- `AZURE_LOCATION`: Azure region for resource deployment

  ```text
  West US 2
  ```

- `KUBERNETES_VERSION`: AKS Kubernetes version

  ```text
  1.28
  ```

- `DOMAIN_NAME`: Custom domain for applications

  ```text
  lucid-mlops.com
  ```

### Feature Flags

- `INSTALL_KUBEFLOW`: Whether to install Kubeflow components

  ```text
  true
  ```

## Setup Instructions

### 1. Create Azure Service Principal

```bash
# Create service principal with contributor role
az ad sp create-for-rbac --name "mlops-platform-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

### 2. Configure GitHub Repository

1. Navigate to your GitHub repository
2. Go to Settings > Secrets and variables > Actions
3. Add the secrets listed above under "Repository secrets"
4. Add the variables listed above under "Repository variables"

### 3. Test the Workflows

1. Push changes to trigger the CI/CD workflow
2. Monitor workflow execution in the Actions tab
3. Check Azure resources are created successfully

## Troubleshooting

### Common Issues

1. **Azure authentication failures**
   - Verify service principal has correct permissions
   - Check subscription ID is correct

2. **Kubernetes access issues**
   - Ensure kubeconfig is properly base64 encoded
   - Verify AKS cluster is accessible

3. **Terraform state issues**
   - Check storage account exists and is accessible
   - Verify container and blob permissions

### Validation Commands

```bash
# Test Azure CLI authentication
az account show

# Test Kubernetes connectivity
kubectl get nodes

# Test MLflow connectivity
curl -X GET ${MLFLOW_TRACKING_URI}/api/2.0/mlflow/experiments/list
```

## Security Best Practices

1. **Rotate secrets regularly** - Update service principal credentials quarterly
2. **Use least privilege** - Grant minimal required permissions to service principals
3. **Monitor access** - Enable Azure AD audit logging for service principal usage
4. **Separate environments** - Use different secrets for staging and production

## Environment-Specific Configuration

### Staging Environment

- Use separate resource groups and storage accounts
- Configure with appropriate resource sizing
- Enable additional monitoring and logging

### Production Environment

- Implement additional security controls
- Use managed identities where possible
- Enable comprehensive backup and disaster recovery

For more information, see the [Azure DevOps best practices documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/security/overview).
