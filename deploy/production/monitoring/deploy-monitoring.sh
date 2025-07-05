#!/bin/bash

# Monitoring Stack Deployment Script for LUCID MLOps Platform
# This script deploys Prometheus and Grafana for monitoring the MLOps platform

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="mlops-monitoring"

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
    
    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
        log_error "Namespace ${NAMESPACE} does not exist. Please create it first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Deploy Prometheus
deploy_prometheus() {
    log_info "Deploying Prometheus..."
    kubectl apply -f "${SCRIPT_DIR}/prometheus.yaml"
    
    # Wait for Prometheus to be ready
    kubectl wait --for=condition=ready pod -l app=prometheus -n ${NAMESPACE} --timeout=300s
    
    log_success "Prometheus deployed and ready"
}

# Deploy Grafana
deploy_grafana() {
    log_info "Deploying Grafana..."
    kubectl apply -f "${SCRIPT_DIR}/grafana.yaml"
    
    # Wait for Grafana to be ready
    kubectl wait --for=condition=ready pod -l app=grafana -n ${NAMESPACE} --timeout=300s
    
    log_success "Grafana deployed and ready"
}

# Configure Grafana datasources and dashboards
configure_grafana() {
    log_info "Configuring Grafana..."
    
    # Wait a bit for Grafana to fully start
    sleep 30
    
    # Get Grafana admin password
    GRAFANA_PASSWORD=$(kubectl get secret grafana-secrets -n ${NAMESPACE} -o jsonpath='{.data.admin-password}' | base64 -d)
    
    # Port forward to Grafana (in background)
    kubectl port-forward svc/grafana -n ${NAMESPACE} 3000:3000 &
    PF_PID=$!
    
    # Wait for port forward to be ready
    sleep 10
    
    # Test Grafana connectivity
    if curl -f -s http://admin:${GRAFANA_PASSWORD}@localhost:3000/api/health > /dev/null; then
        log_success "Grafana is accessible"
    else
        log_warning "Grafana may not be fully ready yet"
    fi
    
    # Stop port forward
    kill $PF_PID 2>/dev/null || true
    
    log_success "Grafana configuration completed"
}

# Display monitoring information
display_info() {
    log_info "Monitoring stack deployment completed successfully!"
    echo ""
    echo "=== Monitoring Information ==="
    echo ""
    
    # Get service status
    log_info "Service Status:"
    kubectl get pods -n ${NAMESPACE}
    echo ""
    
    # Get URLs
    log_info "Access URLs:"
    echo "  Prometheus: https://prometheus.lucid-mlops.com"
    echo "  Grafana: https://grafana.lucid-mlops.com"
    echo ""
    
    # Get credentials
    log_info "Grafana Credentials:"
    echo "  Username: admin"
    echo "  Password: $(kubectl get secret grafana-secrets -n ${NAMESPACE} -o jsonpath='{.data.admin-password}' | base64 -d)"
    echo ""
    
    # Port forwarding instructions
    log_info "For local access (if ingress is not configured):"
    echo "  Prometheus: kubectl port-forward svc/prometheus -n ${NAMESPACE} 9090:9090"
    echo "  Grafana: kubectl port-forward svc/grafana -n ${NAMESPACE} 3000:3000"
    echo ""
    
    log_success "Monitoring stack is ready!"
}

# Main deployment function
main() {
    log_info "Starting monitoring stack deployment..."
    
    # Check if we're running in the correct directory
    if [ ! -f "${SCRIPT_DIR}/prometheus.yaml" ]; then
        log_error "prometheus.yaml not found. Please run this script from the monitoring directory."
        exit 1
    fi
    
    # Run deployment steps
    check_prerequisites
    deploy_prometheus
    deploy_grafana
    configure_grafana
    display_info
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
