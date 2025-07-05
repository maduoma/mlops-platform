#!/bin/bash

# MLOps Platform Demo - Kind Cluster Creation
# This script creates a Kind cluster optimized for MLOps workloads

set -e

CLUSTER_NAME="mlops-platform"
CONFIG_FILE="/tmp/kind-config.yaml"

echo "🚀 Creating MLOps Platform Kind Cluster..."

# Create Kind cluster configuration
cat > ${CONFIG_FILE} << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
- role: worker
  labels:
    workload-type: "ml-training"
- role: worker
  labels:
    workload-type: "ml-serving"
EOF

# Create the cluster
echo "📦 Creating Kind cluster with MLOps configuration..."
kind create cluster --config ${CONFIG_FILE}

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Create namespace for MLOps components
echo "📁 Creating MLOps namespaces..."
kubectl create namespace kubeflow || true
kubectl create namespace mlflow || true
kubectl create namespace kserve || true

# Label nodes for GPU simulation (for demo purposes)
echo "🏷️  Labeling nodes for ML workloads..."
kubectl label nodes ${CLUSTER_NAME}-worker accelerator=gpu-simulation --overwrite || true
kubectl label nodes ${CLUSTER_NAME}-worker2 accelerator=cpu-optimized --overwrite || true

echo "✅ MLOps Platform Kind cluster '${CLUSTER_NAME}' created successfully!"
echo "🔍 Cluster info:"
kubectl cluster-info
echo ""
echo "📋 Available nodes:"
kubectl get nodes -o wide

# Clean up config file
rm -f ${CONFIG_FILE}

echo ""
echo "🎯 Next steps:"
echo "1. Install Kubeflow: ./kubeflow/install_kubeflow.sh"
echo "2. Deploy MLflow: kubectl apply -f mlflow/"
echo "3. Install KServe: ./kserve/install_kserve.sh"