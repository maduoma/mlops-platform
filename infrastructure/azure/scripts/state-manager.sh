#!/bin/bash

# MLOps Platform - State Management Utility
# This script provides utilities for managing Terraform state across environments

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INFRA_DIR="$(dirname "$SCRIPT_DIR")"
readonly ENVIRONMENTS=("dev" "staging" "production")

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

# Show usage information
show_usage() {
    cat << EOF
MLOps Platform - State Management Utility

USAGE:
    $(basename "$0") <command> [environment]

COMMANDS:
    status      - Show state status for all environments or specific environment
    init        - Initialize backend state for environment
    backup      - Create backup of state file
    restore     - Restore state from backup
    lock        - Show lock information
    unlock      - Force unlock state (use with caution)
    refresh     - Refresh state to match real resources
    import      - Import existing resources into state
    help        - Show this help message

ENVIRONMENTS:
    dev         - Development environment
    staging     - Staging environment 
    production  - Production environment

EXAMPLES:
    $(basename "$0") status
    $(basename "$0") status dev
    $(basename "$0") init staging
    $(basename "$0") backup production
    $(basename "$0") unlock dev <lock-id>

EOF
}

# Validate environment
validate_environment() {
    local env="$1"
    
    if [[ ! " ${ENVIRONMENTS[*]} " =~ " ${env} " ]]; then
        log_error "Invalid environment: $env"
        log_info "Valid environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login'"
        exit 1
    fi
}

# Initialize backend for environment
init_backend() {
    local env="$1"
    local backend_config="$INFRA_DIR/environments/$env.backend.conf"
    local state_dir="$INFRA_DIR/state/$env"
    
    log_info "Initializing backend for $env environment..."
    
    if [[ ! -f "$backend_config" ]]; then
        log_error "Backend configuration not found: $backend_config"
        exit 1
    fi
    
    mkdir -p "$state_dir"
    cd "$INFRA_DIR"
    
    terraform init -backend-config="$backend_config" -reconfigure
    
    log_success "Backend initialized for $env environment"
}

# Show state status
show_status() {
    local env="${1:-}"
    
    if [[ -n "$env" ]]; then
        validate_environment "$env"
        show_environment_status "$env"
    else
        log_info "Showing status for all environments:"
        echo
        for environment in "${ENVIRONMENTS[@]}"; do
            show_environment_status "$environment"
            echo
        done
    fi
}

# Show status for specific environment
show_environment_status() {
    local env="$1"
    local backend_config="$INFRA_DIR/environments/$env.backend.conf"
    local state_dir="$INFRA_DIR/state/$env"
    local tfvars_file="$INFRA_DIR/environments/$env.tfvars"
    
    log_info "Environment: $env"
    echo "----------------------------------------"
    
    # Check if backend config exists
    if [[ -f "$backend_config" ]]; then
        log_success "Backend config: ✓ $backend_config"
    else
        log_error "Backend config: ✗ $backend_config"
    fi
    
    # Check if tfvars exists
    if [[ -f "$tfvars_file" ]]; then
        log_success "Variables file: ✓ $tfvars_file"
    else
        log_error "Variables file: ✗ $tfvars_file"
    fi
    
    # Check state directory
    if [[ -d "$state_dir" ]]; then
        log_success "State directory: ✓ $state_dir"
        
        # Show state files if any
        if find "$state_dir" -name "*.json" -o -name "*.tfstate*" | grep -q .; then
            log_info "State files found:"
            find "$state_dir" -name "*.json" -o -name "*.tfstate*" | sed 's/^/  /'
        fi
    else
        log_warning "State directory: ✗ $state_dir (not created)"
    fi
    
    # Try to show Terraform state info if initialized
    cd "$INFRA_DIR"
    if terraform init -backend-config="$backend_config" &> /dev/null; then
        if terraform state list &> /dev/null; then
            local resource_count
            resource_count=$(terraform state list | wc -l)
            log_success "Resources in state: $resource_count"
            
            # Show workspace info
            local workspace
            workspace=$(terraform workspace show 2>/dev/null || echo "default")
            log_info "Current workspace: $workspace"
        else
            log_warning "State not accessible or empty"
        fi
    else
        log_warning "Backend not initialized"
    fi
}

# Create state backup
create_backup() {
    local env="$1"
    local backend_config="$INFRA_DIR/environments/$env.backend.conf"
    local state_dir="$INFRA_DIR/state/$env"
    local backup_dir="$state_dir/backups"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    
    validate_environment "$env"
    
    log_info "Creating backup for $env environment..."
    
    mkdir -p "$backup_dir"
    cd "$INFRA_DIR"
    
    # Initialize backend
    terraform init -backend-config="$backend_config" &> /dev/null
    
    # Pull current state
    terraform state pull > "$backup_dir/terraform.tfstate.$timestamp"
    
    # Also backup outputs if they exist
    if terraform output -json &> /dev/null; then
        terraform output -json > "$backup_dir/outputs.$timestamp.json"
    fi
    
    log_success "Backup created: $backup_dir/terraform.tfstate.$timestamp"
}

# Show lock information
show_lock_info() {
    local env="$1"
    local backend_config="$INFRA_DIR/environments/$env.backend.conf"
    
    validate_environment "$env"
    
    log_info "Checking lock status for $env environment..."
    
    cd "$INFRA_DIR"
    terraform init -backend-config="$backend_config" &> /dev/null
    
    # Try to run a plan to see if state is locked
    if terraform plan -lock-timeout=1s &> /dev/null; then
        log_success "State is not locked"
    else
        log_warning "State appears to be locked or inaccessible"
        log_info "Use 'terraform force-unlock <lock-id>' if you need to force unlock"
    fi
}

# Force unlock state
force_unlock() {
    local env="$1"
    local lock_id="${2:-}"
    local backend_config="$INFRA_DIR/environments/$env.backend.conf"
    
    validate_environment "$env"
    
    if [[ -z "$lock_id" ]]; then
        log_error "Lock ID is required for unlock operation"
        log_info "Usage: $(basename "$0") unlock <environment> <lock-id>"
        exit 1
    fi
    
    log_warning "Force unlocking state for $env environment..."
    log_critical "This should only be done if you're sure no other process is using the state!"
    
    read -p "Are you sure you want to force unlock? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Unlock cancelled"
        exit 0
    fi
    
    cd "$INFRA_DIR"
    terraform init -backend-config="$backend_config" &> /dev/null
    terraform force-unlock "$lock_id"
    
    log_success "State unlocked"
}

# Refresh state
refresh_state() {
    local env="$1"
    local backend_config="$INFRA_DIR/environments/$env.backend.conf"
    local tfvars_file="$INFRA_DIR/environments/$env.tfvars"
    
    validate_environment "$env"
    
    log_info "Refreshing state for $env environment..."
    
    cd "$INFRA_DIR"
    terraform init -backend-config="$backend_config" &> /dev/null
    terraform refresh -var-file="$tfvars_file"
    
    log_success "State refreshed"
}

# Main function
main() {
    local command="${1:-help}"
    local environment="${2:-}"
    local additional_arg="${3:-}"
    
    case "$command" in
        "status")
            check_prerequisites
            show_status "$environment"
            ;;
        "init")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for init command"
                show_usage
                exit 1
            fi
            check_prerequisites
            validate_environment "$environment"
            init_backend "$environment"
            ;;
        "backup")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for backup command"
                show_usage
                exit 1
            fi
            check_prerequisites
            create_backup "$environment"
            ;;
        "lock")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for lock command"
                show_usage
                exit 1
            fi
            check_prerequisites
            show_lock_info "$environment"
            ;;
        "unlock")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for unlock command"
                show_usage
                exit 1
            fi
            check_prerequisites
            force_unlock "$environment" "$additional_arg"
            ;;
        "refresh")
            if [[ -z "$environment" ]]; then
                log_error "Environment is required for refresh command"
                show_usage
                exit 1
            fi
            check_prerequisites
            validate_environment "$environment"
            refresh_state "$environment"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
