#!/bin/bash

# MLOps Platform Demo - Kubeflow Installation
# This script installs Kubeflow components for the MLOps platform

set -e

KUBEFLOW_VERSION="1.8.0"
KUSTOMIZE_VERSION="5.0.3"

echo "🚀 Installing Kubeflow for MLOps Platform..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is required but not installed."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster."
    exit 1
fi

# Install kustomize if not present
if ! command -v kustomize &> /dev/null; then
    echo "📦 Installing Kustomize..."
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize /usr/local/bin/
fi

# Create temporary directory for Kubeflow manifests
TEMP_DIR="/tmp/kubeflow-install"
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}
cd ${TEMP_DIR}

echo "📥 Downloading Kubeflow manifests..."
git clone https://github.com/kubeflow/manifests.git
cd manifests
git checkout v${KUBEFLOW_VERSION}

echo "🔧 Installing Kubeflow components..."

# Install cert-manager (required by many components)
echo "📋 Installing cert-manager..."
kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,cert-manager-cainjector,cert-manager-webhook)' --timeout=180s -n cert-manager

echo "📋 Installing Istio..."
kustomize build common/istio-1-17/istio-crds/base | kubectl apply -f -
kustomize build common/istio-1-17/istio-namespace/base | kubectl apply -f -
kustomize build common/istio-1-17/istio-install/base | kubectl apply -f -

echo "📋 Installing Dex..."
kustomize build common/dex/overlays/istio | kubectl apply -f -

echo "📋 Installing OIDC AuthService..."
kustomize build common/oidc-authservice/base | kubectl apply -f -

echo "📋 Installing Knative Serving..."
kustomize build common/knative/knative-serving/overlays/gateways | kubectl apply -f -
kustomize build common/istio-1-17/cluster-local-gateway/base | kubectl apply -f -

echo "📋 Installing Kubeflow Namespace..."
kustomize build common/kubeflow-namespace/base | kubectl apply -f -

echo "📋 Installing Kubeflow Roles..."
kustomize build common/kubeflow-roles/base | kubectl apply -f -

echo "📋 Installing Kubeflow Istio Resources..."
kustomize build common/istio-1-17/kubeflow-istio-resources/base | kubectl apply -f -

echo "📋 Installing Kubeflow Pipelines..."
kustomize build apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply -f -

echo "📋 Installing Katib (Hyperparameter Tuning)..."
kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -

echo "📋 Installing Central Dashboard..."
kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl apply -f -

echo "📋 Installing Admission Webhook..."
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

echo "📋 Installing Notebook Controller..."
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -

echo "📋 Installing Jupyter Web App..."
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

echo "📋 Installing Profiles + KFAM..."
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -

echo "📋 Installing Volumes Web App..."
kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

echo "📋 Installing Tensorboards Controller..."
kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

echo "📋 Installing Training Operator..."
kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -

echo "📋 Installing User Namespace..."
kustomize build common/user-namespace/base | kubectl apply -f -

echo "⏳ Waiting for Kubeflow components to be ready..."
echo "This may take several minutes..."

# Wait for key components
kubectl wait --for=condition=ready pod -l app=ml-pipeline --timeout=300s -n kubeflow || true
kubectl wait --for=condition=ready pod -l app=katib-controller --timeout=300s -n kubeflow || true
kubectl wait --for=condition=ready pod -l app=centraldashboard --timeout=300s -n kubeflow || true

echo "🌐 Setting up port forwarding for Kubeflow Dashboard..."
echo "You can access Kubeflow at: http://localhost:8080"
echo ""
echo "To access the dashboard, run:"
echo "kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80"
echo ""
echo "Default credentials:"
echo "Email: user@example.com"
echo "Password: 12341234"

# Clean up
cd /
rm -rf ${TEMP_DIR}

echo "✅ Kubeflow installation completed!"
echo ""
echo "🔍 Checking component status:"
kubectl get pods -n kubeflow
echo ""
kubectl get pods -n istio-system