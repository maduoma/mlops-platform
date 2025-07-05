#!/bin/bash

# Infrastructure Deployment Script for LUCID MLOps Platform
# This script deploys Azure infrastructure using Terraform

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../infrastructure/azure"

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

# Show usage
show_usage() {
    echo "Usage: $0 [plan|apply|destroy]"
    echo ""
    echo "Commands:"
    echo "  plan     - Show what Terraform will do"
    echo "  apply    - Apply the infrastructure changes"
    echo "  destroy  - Destroy the infrastructure"
    echo ""
    echo "Examples:"
    echo "  $0 plan"
    echo "  $0 apply"
    echo "  $0 destroy"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        log_info "Install Terraform from: https://learn.hashicorp.com/tutorials/terraform/install-cli"
        exit 1
    fi
    
    # Check if az CLI is available
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed or not in PATH"
        log_info "Install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run 'az login'"
        exit 1
    fi
    
    # Check if terraform directory exists
    if [ ! -d "${TERRAFORM_DIR}" ]; then
        log_error "Terraform directory not found: ${TERRAFORM_DIR}"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    cd "${TERRAFORM_DIR}"
    
    # Initialize Terraform
    terraform init
    
    log_success "Terraform initialized"
}

# Plan infrastructure changes
plan_infrastructure() {
    log_info "Planning infrastructure changes..."
    
    cd "${TERRAFORM_DIR}"
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        log_warning "terraform.tfvars not found, copying from example"
        cp terraform.tfvars.example terraform.tfvars
        log_warning "Please review and modify terraform.tfvars before applying"
    fi
    
    # Plan the changes
    terraform plan -out=tfplan
    
    log_success "Terraform plan completed"
}

# Apply infrastructure changes
apply_infrastructure() {
    log_info "Applying infrastructure changes..."
    
    cd "${TERRAFORM_DIR}"
    
    # Check if plan exists
    if [ ! -f "tfplan" ]; then
        log_warning "No plan file found, creating plan first..."
        plan_infrastructure
    fi
    
    # Apply the changes
    terraform apply tfplan
    
    # Remove the plan file
    rm -f tfplan
    
    # Get outputs
    log_info "Getting Terraform outputs..."
    terraform output
    
    # Save kubeconfig
    log_info "Configuring kubectl..."
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
    
    log_success "Infrastructure deployment completed"
}

# Destroy infrastructure
destroy_infrastructure() {
    log_info "Destroying infrastructure..."
    log_warning "This will permanently delete all resources!"
    
    read -p "Are you sure you want to destroy the infrastructure? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    cd "${TERRAFORM_DIR}"
    
    # Destroy the infrastructure
    terraform destroy -auto-approve
    
    log_success "Infrastructure destroyed"
}

# Display infrastructure information
display_info() {
    log_info "Infrastructure Information"
    echo ""
    
    cd "${TERRAFORM_DIR}"
    
    # Check if state file exists
    if [ ! -f "terraform.tfstate" ]; then
        log_warning "No Terraform state found. Infrastructure may not be deployed."
        return
    fi
    
    # Display outputs
    terraform output
    echo ""
    
    # Display cluster info
    log_info "Cluster Information:"
    kubectl cluster-info 2>/dev/null || log_warning "Cannot connect to cluster"
    echo ""
    
    log_info "Next Steps:"
    echo "1. Deploy the MLOps platform: cd deploy/production && ./deploy.sh"
    echo "2. Access Kubeflow: kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80"
    echo "3. Access MLflow: https://mlflow.lucid-mlops.com"
    echo ""
}

# Main function
main() {
    local command="${1:-}"
    
    if [ -z "$command" ]; then
        show_usage
        exit 1
    fi
    
    case "$command" in
        "plan")
            check_prerequisites
            init_terraform
            plan_infrastructure
            ;;
        "apply")
            check_prerequisites
            init_terraform
            plan_infrastructure
            apply_infrastructure
            display_info
            ;;
        "destroy")
            check_prerequisites
            init_terraform
            destroy_infrastructure
            ;;
        "info")
            display_info
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
