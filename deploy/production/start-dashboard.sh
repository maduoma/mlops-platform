#!/bin/bash
# MLOps Platform Dashboard Access
# Provides secure web access to Kubernetes resources

set -e

echo "🎯 Starting MLOps Platform Dashboard Access..."

# Function to start kubectl proxy with proper authentication
start_proxy() {
    echo "🔐 Starting authenticated kubectl proxy..."
    
    # Kill any existing proxy
    pkill -f "kubectl proxy" || true
    sleep 2
    
    # Start proxy with authentication
    kubectl proxy --port=8080 --address='127.0.0.1' --accept-hosts='^localhost$,^127\.0\.0\.1$,^\[::1\]$' &
    PROXY_PID=$!
    
    echo "✅ Kubectl proxy started (PID: $PROXY_PID)"
    echo "   📡 Proxy URL: http://localhost:8080"
    
    # Wait for proxy to be ready
    echo "⏳ Waiting for proxy to be ready..."
    for i in {1..10}; do
        if curl -s http://localhost:8080/api/v1/namespaces > /dev/null 2>&1; then
            echo "✅ Proxy is ready!"
            break
        fi
        sleep 1
    done
}

# Function to show available endpoints
show_endpoints() {
    echo ""
    echo "🎯 Available MLOps Platform Endpoints:"
    echo "======================================"
    echo ""
    echo "📊 Namespaces:"
    echo "• Production:  http://localhost:8080/api/v1/namespaces/mlops-production"
    echo "• Monitoring:  http://localhost:8080/api/v1/namespaces/mlops-monitoring"
    echo "• Serving:     http://localhost:8080/api/v1/namespaces/mlops-serving"
    echo ""
    echo "🔍 Resources:"
    echo "• All Pods:    http://localhost:8080/api/v1/pods"
    echo "• Services:    http://localhost:8080/api/v1/services"
    echo "• Deployments: http://localhost:8080/apis/apps/v1/deployments"
    echo ""
    echo "📈 Metrics (if available):"
    echo "• Node Metrics: http://localhost:8080/apis/metrics.k8s.io/v1beta1/nodes"
    echo "• Pod Metrics:  http://localhost:8080/apis/metrics.k8s.io/v1beta1/pods"
    echo ""
    echo "🎯 MLOps Specific:"
    echo "• Production Pods: http://localhost:8080/api/v1/namespaces/mlops-production/pods"
    echo "• Monitoring SVC:  http://localhost:8080/api/v1/namespaces/mlops-monitoring/services"
    echo "• Serving Deploy:  http://localhost:8080/apis/apps/v1/namespaces/mlops-serving/deployments"
}

# Function to test endpoints
test_endpoints() {
    echo ""
    echo "🧪 Testing MLOps Platform Endpoints:"
    echo "===================================="
    
    # Test namespace access
    echo "📊 Testing namespace access..."
    for ns in mlops-production mlops-monitoring mlops-serving; do
        if curl -s "http://localhost:8080/api/v1/namespaces/$ns" | grep -q "Active"; then
            echo "  ✅ $ns: Active"
        else
            echo "  ❌ $ns: Not accessible"
        fi
    done
    
    # Test resource access
    echo ""
    echo "🔍 Testing resource access..."
    if curl -s "http://localhost:8080/api/v1/pods" | grep -q "PodList"; then
        echo "  ✅ Pods: Accessible"
    else
        echo "  ❌ Pods: Not accessible"
    fi
    
    if curl -s "http://localhost:8080/api/v1/services" | grep -q "ServiceList"; then
        echo "  ✅ Services: Accessible"
    else
        echo "  ❌ Services: Not accessible"
    fi
}

# Main execution
main() {
    start_proxy
    show_endpoints
    test_endpoints
    
    echo ""
    echo "🎯 MLOps Dashboard Access Ready!"
    echo "==============================="
    echo ""
    echo "✅ You can now access the Kubernetes API through the proxy at:"
    echo "   🌐 http://localhost:8080"
    echo ""
    echo "💡 Pro Tips:"
    echo "• Use the endpoints above to access specific resources"
    echo "• The proxy handles authentication automatically"
    echo "• Add '/api/v1' prefix for core resources"
    echo "• Add '/apis/GROUP/VERSION' for custom resources"
    echo ""
    echo "🔥 Example Commands:"
    echo "curl http://localhost:8080/api/v1/namespaces/mlops-production"
    echo "curl http://localhost:8080/api/v1/namespaces/mlops-production/pods"
    echo ""
    echo "🛑 To stop the proxy: pkill -f 'kubectl proxy'"
    echo ""
    echo "📊 Proxy is running in background (PID: $PROXY_PID)"
    echo "   Press Ctrl+C to stop this script (proxy will continue running)"
    
    # Keep script running to show logs
    echo ""
    echo "📋 Monitoring proxy logs (Ctrl+C to exit)..."
    tail -f /dev/null
}

# Handle script termination
cleanup() {
    echo ""
    echo "🛑 Stopping MLOps Dashboard Access..."
    pkill -f "kubectl proxy" || true
    echo "✅ Cleanup complete"
    exit 0
}

trap cleanup INT TERM

# Run main function
main
