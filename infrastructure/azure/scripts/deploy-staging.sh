#!/bin/bash

# MLOps Platform - Staging Environment Deployment Script
# This script deploys the staging environment with proper state management

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly ENVIRONMENT="staging"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INFRA_DIR="$(dirname "$SCRIPT_DIR")"
readonly STATE_DIR="$INFRA_DIR/state/$ENVIRONMENT"
readonly BACKEND_CONFIG="$INFRA_DIR/environments/$ENVIRONMENT.backend.conf"
readonly TFVARS_FILE="$INFRA_DIR/environments/$ENVIRONMENT.tfvars"

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

# Validation functions
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login'"
        exit 1
    fi
    
    # Check if required files exist
    if [[ ! -f "$BACKEND_CONFIG" ]]; then
        log_error "Backend configuration file not found: $BACKEND_CONFIG"
        exit 1
    fi
    
    if [[ ! -f "$TFVARS_FILE" ]]; then
        log_error "Terraform variables file not found: $TFVARS_FILE"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Initialize Terraform backend
init_terraform() {
    log_info "Initializing Terraform for $ENVIRONMENT environment..."
    
    cd "$INFRA_DIR"
    
    # Create state directory if it doesn't exist
    mkdir -p "$STATE_DIR"
    
    # Initialize Terraform with backend configuration
    terraform init \
        -backend-config="$BACKEND_CONFIG" \
        -reconfigure
    
    log_success "Terraform initialized successfully"
}

# Plan deployment
plan_deployment() {
    log_info "Planning deployment for $ENVIRONMENT environment..."
    
    cd "$INFRA_DIR"
    
    # Create a plan file for review
    terraform plan \
        -var-file="$TFVARS_FILE" \
        -out="$STATE_DIR/terraform.plan"
    
    log_success "Deployment plan created at $STATE_DIR/terraform.plan"
}

# Apply deployment
apply_deployment() {
    log_info "Applying deployment for $ENVIRONMENT environment..."
    
    cd "$INFRA_DIR"
    
    # Apply the plan
    terraform apply "$STATE_DIR/terraform.plan"
    
    log_success "Deployment completed successfully for $ENVIRONMENT environment"
}

# Output deployment information
show_outputs() {
    log_info "Displaying deployment outputs..."
    
    cd "$INFRA_DIR"
    
    terraform output -json > "$STATE_DIR/outputs.json"
    terraform output
    
    log_success "Outputs saved to $STATE_DIR/outputs.json"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    # Remove plan file after successful deployment
    if [[ -f "$STATE_DIR/terraform.plan" ]]; then
        rm -f "$STATE_DIR/terraform.plan"
    fi
}

# Main deployment function
main() {
    log_info "Starting deployment for $ENVIRONMENT environment"
    log_info "State directory: $STATE_DIR"
    log_info "Backend config: $BACKEND_CONFIG"
    log_info "Variables file: $TFVARS_FILE"
    
    # Execute deployment steps
    check_prerequisites
    init_terraform
    plan_deployment
    
    # Prompt for confirmation before applying
    echo
    log_warning "Review the plan above carefully!"
    log_warning "This is the STAGING environment - ensure you understand the impact!"
    read -p "Do you want to apply this deployment? (yes/no): " -r
    echo
    
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        apply_deployment
        show_outputs
        cleanup
        
        echo
        log_success "Staging environment deployment completed successfully!"
        log_info "You can view the outputs in: $STATE_DIR/outputs.json"
    else
        log_info "Deployment cancelled by user"
        exit 0
    fi
}

# Trap to ensure cleanup on script exit
trap cleanup EXIT

# Execute main function
main "$@"
