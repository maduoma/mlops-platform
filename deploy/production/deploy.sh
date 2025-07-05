#!/bin/bash

# Production Deployment Script for LUCID MLOps Platform
# This script deploys the MLOps platform to a production Kubernetes cluster

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE_PRODUCTION="mlops-production"
NAMESPACE_MONITORING="mlops-monitoring"
NAMESPACE_SERVING="mlops-serving"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespaces
create_namespaces() {
    log_info "Creating namespaces..."
    kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
    log_success "Namespaces created"
}

# Install cert-manager for TLS certificates
install_cert_manager() {
    log_info "Installing cert-manager..."
    
    # Add cert-manager helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Install cert-manager
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.13.0 \
        --set installCRDs=true \
        --set global.leaderElection.namespace=cert-manager
    
    # Wait for cert-manager to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
    
    log_success "cert-manager installed"
}

# Install NGINX Ingress Controller
install_nginx_ingress() {
    log_info "Installing NGINX Ingress Controller..."
    
    # Add ingress-nginx helm repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Install ingress-nginx
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.replicaCount=2 \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.service.type=LoadBalancer \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
    
    # Wait for ingress controller to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s
    
    log_success "NGINX Ingress Controller installed"
}

# Deploy PostgreSQL
deploy_postgres() {
    log_info "Deploying PostgreSQL..."
    kubectl apply -f "${SCRIPT_DIR}/postgres.yaml"
    
    # Wait for PostgreSQL to be ready
    kubectl wait --for=condition=ready pod -l app=postgres -n ${NAMESPACE_PRODUCTION} --timeout=300s
    
    log_success "PostgreSQL deployed"
}

# Deploy MLflow
deploy_mlflow() {
    log_info "Deploying MLflow..."
    kubectl apply -f "${SCRIPT_DIR}/mlflow-production.yaml"
    
    # Wait for MLflow to be ready
    kubectl wait --for=condition=ready pod -l app=mlflow-server -n ${NAMESPACE_PRODUCTION} --timeout=300s
    
    log_success "MLflow deployed"
}

# Deploy monitoring stack
deploy_monitoring() {
    log_info "Deploying monitoring stack..."
    
    # Deploy monitoring manifests
    if [ -d "${SCRIPT_DIR}/monitoring" ]; then
        kubectl apply -f "${SCRIPT_DIR}/monitoring/"
        log_success "Monitoring stack deployed"
    else
        log_warning "Monitoring directory not found, skipping monitoring deployment"
    fi
}

# Install Kubeflow
install_kubeflow() {
    log_info "Installing Kubeflow..."
    
    # Check if kustomize is available
    if ! command -v kustomize &> /dev/null; then
        log_warning "kustomize not found, installing..."
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/
    fi
    
    # Clone Kubeflow manifests
    if [ ! -d "/tmp/kubeflow-manifests" ]; then
        git clone https://github.com/kubeflow/manifests.git /tmp/kubeflow-manifests
        cd /tmp/kubeflow-manifests
        git checkout v1.8.0
    fi
    
    # Install Kubeflow
    cd /tmp/kubeflow-manifests
    while ! kustomize build example | kubectl apply -f -; do
        log_info "Retrying Kubeflow installation..."
        sleep 10
    done
    
    log_success "Kubeflow installed"
}

# Install KServe
install_kserve() {
    log_info "Installing KServe..."
    
    # Install KServe
    kubectl apply -f https://github.com/kserve/kserve/releases/download/v0.11.0/kserve.yaml
    kubectl apply -f https://github.com/kserve/kserve/releases/download/v0.11.0/kserve-runtimes.yaml
    
    # Wait for KServe to be ready
    kubectl wait --for=condition=ready pod -l control-plane=kserve-controller-manager -n kserve --timeout=300s
    
    log_success "KServe installed"
}

# Setup RBAC
setup_rbac() {
    log_info "Setting up RBAC..."
    kubectl apply -f "${SCRIPT_DIR}/../rbac/mlops-rbac.yaml"
    log_success "RBAC configured"
}

# Display deployment information
display_info() {
    log_info "Deployment completed successfully!"
    echo ""
    echo "=== Deployment Information ==="
    echo ""
    
    # Get ingress information
    log_info "Ingress Controller External IP:"
    kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending..."
    echo ""
    
    # Get MLflow URL
    log_info "MLflow URL: https://mlflow.lucid-mlops.com"
    echo ""
    
    # Get service status
    log_info "Service Status:"
    kubectl get pods -n ${NAMESPACE_PRODUCTION}
    echo ""
    
    # Get Kubeflow URL
    log_info "Kubeflow Central Dashboard:"
    echo "kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80"
    echo "Then visit: http://localhost:8080"
    echo ""
    
    log_info "To configure DNS, point the following domains to the ingress IP:"
    echo "  - mlflow.lucid-mlops.com"
    echo "  - kubeflow.lucid-mlops.com"
    echo ""
    
    log_success "Production deployment completed!"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf /tmp/kubeflow-manifests
}

# Main deployment function
main() {
    log_info "Starting LUCID MLOps Platform production deployment..."
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Check if we're running in the correct directory
    if [ ! -f "${SCRIPT_DIR}/namespace.yaml" ]; then
        log_error "namespace.yaml not found. Please run this script from the deploy/production directory."
        exit 1
    fi
    
    # Run deployment steps
    check_prerequisites
    create_namespaces
    install_cert_manager
    install_nginx_ingress
    deploy_postgres
    deploy_mlflow
    deploy_monitoring
    setup_rbac
    install_kubeflow
    install_kserve
    display_info
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
