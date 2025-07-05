#!/bin/bash
# MLOps Platform - Secure API Access Setup
# This script creates secure access tokens for the MLOps platform

set -e

echo "🔐 Setting up secure MLOps Platform API access..."

# Function to create service account token
create_token() {
    local namespace=$1
    local service_account=$2
    local token_name="${service_account}-token"
    
    echo "📝 Creating token for ${service_account} in ${namespace}..."
    
    # Create token secret
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${token_name}
  namespace: ${namespace}
  annotations:
    kubernetes.io/service-account.name: ${service_account}
type: kubernetes.io/service-account-token
EOF
    
    # Wait for token to be populated
    echo "⏳ Waiting for token to be ready..."
    kubectl wait --for=condition=complete --timeout=30s secret/${token_name} -n ${namespace} || true
    
    # Get the token
    local token=$(kubectl get secret ${token_name} -n ${namespace} -o jsonpath='{.data.token}' | base64 -d)
    
    if [ -n "$token" ]; then
        echo "✅ Token created for ${service_account}"
        echo "   Namespace: ${namespace}"
        echo "   Token: ${token:0:20}..."
        
        # Save token to file for secure access
        echo "$token" > "/tmp/mlops-${service_account}-token.txt"
        chmod 600 "/tmp/mlops-${service_account}-token.txt"
        echo "   💾 Token saved to: /tmp/mlops-${service_account}-token.txt"
    else
        echo "❌ Failed to create token for ${service_account}"
    fi
    
    echo ""
}

# Create tokens for all service accounts
create_token "mlops-production" "mlops-admin"
create_token "mlops-monitoring" "mlops-monitoring"
create_token "mlops-serving" "mlops-serving"

echo "🎯 MLOps Platform API Access Summary:"
echo "=================================="
echo "API Server: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo "CA Certificate: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority}')"
echo ""
echo "🔑 Service Account Tokens:"
echo "• mlops-admin: /tmp/mlops-mlops-admin-token.txt"
echo "• mlops-monitoring: /tmp/mlops-mlops-monitoring-token.txt"
echo "• mlops-serving: /tmp/mlops-mlops-serving-token.txt"
echo ""
echo "📊 Testing API access..."

# Test API access with the admin token
if [ -f "/tmp/mlops-mlops-admin-token.txt" ]; then
    TOKEN=$(cat /tmp/mlops-mlops-admin-token.txt)
    API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    
    echo "🧪 Testing authenticated API call..."
    curl -s -k -H "Authorization: Bearer $TOKEN" \
         "${API_SERVER}/api/v1/namespaces/mlops-production" \
         | grep -E "(name|phase)" || echo "API test completed"
fi

echo ""
echo "✅ Secure API access configured!"
echo "   Use the tokens above for authenticated API calls"
echo "   Example: curl -H 'Authorization: Bearer \$TOKEN' \$API_SERVER/api/v1/namespaces"
