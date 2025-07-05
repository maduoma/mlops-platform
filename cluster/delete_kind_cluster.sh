#!/bin/bash

# MLOps Platform Demo - Cluster Cleanup
# This script safely deletes the Kind cluster and cleans up resources

set -e

CLUSTER_NAME="mlops-platform"

echo "🗑️  Cleaning up MLOps Platform..."

# Check if cluster exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "📦 Found cluster '${CLUSTER_NAME}', proceeding with deletion..."
    
    # Optional: Save important data before deletion
    echo "💾 Backing up important data (optional)..."
    
    # Create backup directory
    BACKUP_DIR="/tmp/mlops-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p ${BACKUP_DIR}
    
    # Backup MLflow data (if accessible)
    echo "📊 Attempting to backup MLflow experiments..."
    kubectl get pods -n mlflow &> /dev/null && \
    kubectl exec -n mlflow deployment/mlflow-server -- tar czf - /mlflow 2>/dev/null | \
    cat > ${BACKUP_DIR}/mlflow-backup.tar.gz || \
    echo "⚠️  Could not backup MLflow data (cluster may not be accessible)"
    
    # Backup important configs
    echo "📋 Backing up configurations..."
    kubectl get configmaps -A -o yaml > ${BACKUP_DIR}/configmaps.yaml 2>/dev/null || true
    kubectl get secrets -A -o yaml > ${BACKUP_DIR}/secrets.yaml 2>/dev/null || true
    
    echo "💾 Backup saved to: ${BACKUP_DIR}"
    
    # Delete the cluster
    echo "🔥 Deleting Kind cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name ${CLUSTER_NAME}
    
    echo "✅ Cluster '${CLUSTER_NAME}' deleted successfully!"
    
else
    echo "❌ Cluster '${CLUSTER_NAME}' not found."
    echo "📋 Available clusters:"
    kind get clusters
fi

# Clean up any remaining Docker images (optional)
echo "🧹 Cleaning up Docker images..."
docker images | grep -E "(kubeflow|mlflow|kserve)" | awk '{print $3}' | xargs -r docker rmi -f || true

# Clean up temporary files
echo "🧽 Cleaning up temporary files..."
rm -f /tmp/kind-config.yaml
rm -rf /tmp/kubeflow-install

echo ""
echo "🎯 Cleanup Summary:"
echo "✅ Kind cluster deleted"
echo "✅ Docker images cleaned"
echo "✅ Temporary files removed"
if [ -d "${BACKUP_DIR}" ]; then
    echo "💾 Backup available at: ${BACKUP_DIR}"
fi
echo ""
echo "🚀 To recreate the platform, run: ./cluster/create_kind_cluster.sh"