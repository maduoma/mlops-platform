#!/bin/bash

# MLOps Platform - Production Environment Deployment Script
# This script deploys the production environment with proper state management
# CRITICAL: This deploys to PRODUCTION - requires additional safeguards

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Configuration
readonly ENVIRONMENT="production"
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

log_critical() {
    echo -e "${PURPLE}[CRITICAL]${NC} $1"
}

# Enhanced validation for production
check_prerequisites() {
    log_info "Checking prerequisites for PRODUCTION deployment..."
    
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
    
    # Verify we're in the correct subscription for production
    local current_subscription
    current_subscription=$(az account show --query "name" -o tsv)
    log_warning "Current Azure subscription: $current_subscription"
    
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

# Production safety checks
production_safety_checks() {
    log_critical "PRODUCTION DEPLOYMENT SAFETY CHECKS"
    echo "======================================"
    
    # Require explicit confirmation for production
    echo
    log_critical "You are about to deploy to PRODUCTION environment!"
    log_critical "This can affect live systems and user data!"
    echo
    
    read -p "Type 'PRODUCTION' to confirm you understand the risks: " -r
    if [[ $REPLY != "PRODUCTION" ]]; then
        log_error "Production deployment cancelled - confirmation failed"
        exit 1
    fi
    
    # Additional confirmation
    read -p "Are you absolutely sure you want to deploy to production? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_error "Production deployment cancelled by user"
        exit 1
    fi
    
    log_success "Production safety checks passed"
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

# Plan deployment with enhanced checks for production
plan_deployment() {
    log_info "Planning deployment for $ENVIRONMENT environment..."
    
    cd "$INFRA_DIR"
    
    # Create a plan file for review
    terraform plan \
        -var-file="$TFVARS_FILE" \
        -out="$STATE_DIR/terraform.plan" \
        -detailed-exitcode
    
    local plan_exit_code=$?
    
    case $plan_exit_code in
        0)
            log_info "No changes required - infrastructure is up to date"
            ;;
        2)
            log_warning "Changes detected - review the plan carefully!"
            ;;
        *)
            log_error "Terraform plan failed with exit code: $plan_exit_code"
            exit 1
            ;;
    esac
    
    log_success "Deployment plan created at $STATE_DIR/terraform.plan"
}

# Apply deployment with additional production safeguards
apply_deployment() {
    log_info "Applying deployment for $ENVIRONMENT environment..."
    
    cd "$INFRA_DIR"
    
    # Final confirmation before applying to production
    echo
    log_critical "FINAL CONFIRMATION REQUIRED"
    log_critical "You are about to apply changes to PRODUCTION!"
    read -p "Type 'APPLY' to proceed: " -r
    
    if [[ $REPLY != "APPLY" ]]; then
        log_error "Production deployment cancelled - final confirmation failed"
        exit 1
    fi
    
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
    log_critical "PRODUCTION ENVIRONMENT DEPLOYMENT"
    log_critical "=================================="
    log_info "State directory: $STATE_DIR"
    log_info "Backend config: $BACKEND_CONFIG"
    log_info "Variables file: $TFVARS_FILE"
    
    # Execute deployment steps with enhanced checks
    check_prerequisites
    production_safety_checks
    init_terraform
    plan_deployment
    
    # Enhanced review process for production
    echo
    log_critical "MANDATORY PLAN REVIEW"
    log_warning "Review the plan above VERY carefully!"
    log_warning "Verify all changes are expected and approved!"
    echo
    
    read -p "Have you thoroughly reviewed the plan and want to proceed? (yes/no): " -r
    echo
    
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        apply_deployment
        show_outputs
        cleanup
        
        echo
        log_success "Production environment deployment completed successfully!"
        log_critical "IMPORTANT: Verify that all systems are working correctly!"
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
