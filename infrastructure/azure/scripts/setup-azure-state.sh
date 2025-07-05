#!/bin/bash
# MLOps Platform - Azure Storage Setup for Terraform State Management
# Creates storage accounts for multi-environment state management

set -e

echo "🔧 Setting up Azure Storage for Terraform State Management"
echo "=================================================="

# Variables
RESOURCE_GROUP="mlops-terraform-state"
LOCATION="East US"

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

echo "✅ Azure CLI is available and logged in"

# Create resource group if it doesn't exist
echo "📦 Creating resource group: $RESOURCE_GROUP"
az group create \
    --name $RESOURCE_GROUP \
    --location "$LOCATION" \
    --tags Project=MLOps-Platform Purpose=Terraform-State \
    --output table

# Create storage accounts for each environment
ENVIRONMENTS=("dev" "staging" "prod")

for env in "${ENVIRONMENTS[@]}"; do
    STORAGE_ACCOUNT="mlopstfstate${env}"
    
    echo ""
    echo "🏗️  Creating storage account for ${env} environment..."
    echo "Storage Account: $STORAGE_ACCOUNT"
    
    # Create storage account
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $RESOURCE_GROUP \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --encryption-services blob \
        --enable-https-traffic-only true \
        --min-tls-version TLS1_2 \
        --tags Environment=$env Project=MLOps-Platform Purpose=Terraform-State \
        --output table
    
    echo "📦 Creating tfstate container in $STORAGE_ACCOUNT..."
    
    # Create container for terraform state
    az storage container create \
        --name tfstate \
        --account-name $STORAGE_ACCOUNT \
        --auth-mode login \
        --public-access off \
        --output table
    
    # Enable versioning on the storage account
    echo "🔄 Enabling blob versioning for $STORAGE_ACCOUNT..."
    az storage account blob-service-properties update \
        --account-name $STORAGE_ACCOUNT \
        --enable-versioning true \
        --enable-change-feed true \
        --change-feed-retention-days 30 \
        --enable-delete-retention true \
        --delete-retention-days 30 \
        --output table
        
    echo "✅ Storage setup completed for ${env} environment"
done

echo ""
echo "🎯 All Terraform state storage accounts created successfully!"
echo "=================================================="
echo ""
echo "📝 Next steps:"
echo "1. Deploy to development: ./scripts/deploy-dev.sh"
echo "2. Deploy to staging:     ./scripts/deploy-staging.sh"
echo "3. Deploy to production:  ./scripts/deploy-production.sh"
echo ""
echo "💡 Backend configurations are in environments/*.backend.conf"
echo "💡 Environment variables are in environments/*.tfvars"
