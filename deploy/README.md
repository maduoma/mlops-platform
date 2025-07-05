# Production Deployment Guide

This directory contains all the necessary files and scripts for deploying the LUCID MLOps Platform to production.

## Directory Structure

```folder structure
deploy/
├── deploy-infrastructure.sh     # Infrastructure deployment script
├── production/
│   ├── deploy.sh               # Production deployment script
│   ├── namespace.yaml          # Kubernetes namespaces
│   ├── mlflow-production.yaml  # MLflow production configuration
│   ├── postgres.yaml           # PostgreSQL database
│   └── monitoring/
│       ├── deploy-monitoring.sh # Monitoring deployment script
│       ├── prometheus.yaml      # Prometheus configuration
│       └── grafana.yaml         # Grafana configuration
└── README.md                   # This file
```

## Prerequisites

### Required Tools

1. **Azure CLI** - For Azure authentication and resource management

   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Terraform** - For infrastructure as code

   ```bash
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl** - For Kubernetes management

   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

4. **Helm** - For Kubernetes package management

   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

### Azure Prerequisites

1. **Azure Subscription** - Active Azure subscription
2. **Azure CLI Authentication**

   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Azure Resource Providers** (register if needed)

   ```bash
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.Storage
   az provider register --namespace Microsoft.KeyVault
   az provider register --namespace Microsoft.OperationalInsights
   ```

## Deployment Steps

### Step 1: Infrastructure Deployment

Deploy the Azure infrastructure (AKS, ACR, Storage, etc.):

```bash
# Plan the infrastructure
./deploy-infrastructure.sh plan

# Review the plan and apply
./deploy-infrastructure.sh apply
```

This will create:

- AKS cluster with system and ML training node pools
- Azure Container Registry (ACR)
- Storage account for MLflow artifacts
- Azure Key Vault for secrets
- Log Analytics workspace
- Virtual network and subnets

### Step 2: Platform Deployment

Deploy the MLOps platform components:

```bash
cd production/
./deploy.sh
```

This will deploy:

- Kubernetes namespaces
- cert-manager for TLS certificates
- NGINX Ingress Controller
- PostgreSQL database
- MLflow tracking server
- Monitoring stack (Prometheus & Grafana)
- RBAC configurations
- Kubeflow Pipelines
- KServe for model serving

### Step 3: DNS Configuration

Configure your DNS to point to the ingress controller:

1. Get the ingress controller external IP:

   ```bash
   kubectl get service ingress-nginx-controller -n ingress-nginx
   ```

2. Create DNS A records pointing to this IP:
   - `mlflow.lucid-mlops.com`
   - `grafana.lucid-mlops.com`
   - `prometheus.lucid-mlops.com`
   - `kubeflow.lucid-mlops.com`

### Step 4: Verify Deployment

Check that all services are running:

```bash
# Check all pods
kubectl get pods --all-namespaces

# Check MLOps production namespace
kubectl get pods -n mlops-production

# Check monitoring namespace
kubectl get pods -n mlops-monitoring
```

## Post-Deployment Configuration

### MLflow Configuration

1. Access MLflow UI: `https://mlflow.lucid-mlops.com`
2. Configure experiment tracking in your ML code:

   ```python
   import mlflow
   mlflow.set_tracking_uri("https://mlflow.lucid-mlops.com")
   ```

### Kubeflow Access

1. Port-forward to Kubeflow:

   ```bash
   kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
   ```

2. Access: `http://localhost:8080`

### Monitoring Access

1. **Grafana**: `https://grafana.lucid-mlops.com`
   - Username: `admin`
   - Password: Get from secret:

     ```bash
     kubectl get secret grafana-secrets -n mlops-monitoring -o jsonpath='{.data.admin-password}' | base64 -d
     ```

2. **Prometheus**: `https://prometheus.lucid-mlops.com`

## Security Considerations

### Production Secrets

Before production deployment, update these default passwords:

1. **PostgreSQL passwords** in `postgres.yaml`:

   ```bash
   echo -n "your-secure-password" | base64
   ```

2. **Grafana admin password** in `monitoring/grafana.yaml`:

   ```bash
   echo -n "your-secure-password" | base64
   ```

### TLS Certificates

The deployment uses Let's Encrypt for TLS certificates. Ensure:

1. DNS records are properly configured
2. cert-manager can reach Let's Encrypt endpoints
3. Domains resolve correctly

### RBAC

Review and customize RBAC policies in `../rbac/mlops-rbac.yaml` based on your organization's requirements.

## Scaling and Optimization

### Auto-scaling

The deployment includes:

- **Cluster autoscaler**: Automatically adds/removes nodes
- **Horizontal Pod Autoscaler**: Scales pods based on CPU/memory
- **Vertical Pod Autoscaler**: Adjusts pod resource requests

### Resource Optimization

1. **Node pools**:
   - System pool: General workloads
   - ML training pool: GPU-enabled for ML training

2. **Storage classes**:
   - Premium SSD for databases
   - Standard storage for logs

### Monitoring and Alerting

Pre-configured alerts for:

- Service health (MLflow, PostgreSQL)
- Resource utilization (CPU, memory)
- Model serving latency

## Troubleshooting

### Common Issues

1. **TLS certificate issues**:

   ```bash
   kubectl describe certificaterequests -n mlops-production
   kubectl logs -n cert-manager deployment/cert-manager
   ```

2. **Ingress not working**:

   ```bash
   kubectl describe ingress -n mlops-production
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

3. **Pod startup issues**:

   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

### Useful Commands

```bash
# Get all resources in a namespace
kubectl get all -n mlops-production

# Check resource usage
kubectl top nodes
kubectl top pods -n mlops-production

# Port forward for local access
kubectl port-forward svc/mlflow-server -n mlops-production 5000:5000
kubectl port-forward svc/grafana -n mlops-monitoring 3000:3000

# Check logs
kubectl logs -f deployment/mlflow-server -n mlops-production
kubectl logs -f deployment/postgres -n mlops-production
```

## Backup and Recovery

### Database Backup

Set up automated PostgreSQL backups:

```bash
# Manual backup
kubectl exec deployment/postgres -n mlops-production -- pg_dump -U postgres mlflowdb > backup.sql

# Restore
kubectl exec -i deployment/postgres -n mlops-production -- psql -U postgres mlflowdb < backup.sql
```

### Disaster Recovery

1. **Infrastructure**: Terraform state is stored in Azure Storage
2. **Data**: PostgreSQL data is on persistent volumes
3. **Secrets**: Backed up in Azure Key Vault

## Maintenance

### Updates

1. **Infrastructure updates**: Modify Terraform configuration and apply
2. **Application updates**: Update container images and redeploy
3. **Kubernetes updates**: Use AKS managed updates

### Health Checks

Regular monitoring includes:

- Service availability
- Resource utilization
- Storage capacity
- Certificate expiration

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review Kubernetes events: `kubectl get events --sort-by='.lastTimestamp'`
3. Check application logs as shown in troubleshooting commands
4. Consult the main project README for architecture details

---

## Quick Reference

### Essential Commands

```bash
# Deploy infrastructure
./deploy-infrastructure.sh apply

# Deploy platform
cd production && ./deploy.sh

# Check status
kubectl get pods --all-namespaces

# Access services locally
kubectl port-forward svc/mlflow-server -n mlops-production 5000:5000
kubectl port-forward svc/grafana -n mlops-monitoring 3000:3000
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80

# Destroy everything
./deploy-infrastructure.sh destroy
```

### Important URLs

- MLflow: `https://mlflow.lucid-mlops.com`
- Grafana: `https://grafana.lucid-mlops.com`
- Prometheus: `https://prometheus.lucid-mlops.com`
- Kubeflow: `http://localhost:8080` (port-forward required)
