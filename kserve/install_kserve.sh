#!/bin/bash

# MLOps Platform Demo - KServe Installation
# This script installs KServe for model serving in the MLOps platform

set -e

KSERVE_VERSION="v0.11.2"
KNATIVE_VERSION="1.11.0"

echo "🚀 Installing KServe for MLOps Platform..."

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is required but not installed."
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster."
    exit 1
fi

echo "📦 Installing Knative Serving (prerequisite for KServe)..."

# Install Knative Serving CRDs
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-crds.yaml

# Install Knative Serving core
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-core.yaml

# Wait for Knative to be ready
echo "⏳ Waiting for Knative Serving to be ready..."
kubectl wait --for=condition=ready pod -l app=controller --timeout=300s -n knative-serving
kubectl wait --for=condition=ready pod -l app=activator --timeout=300s -n knative-serving

# Install Istio networking layer for Knative (if not already installed)
if ! kubectl get namespace istio-system &> /dev/null; then
    echo "📦 Installing Istio for Knative networking..."
    kubectl apply -l knative.dev/crd-install=true -f https://github.com/knative/net-istio/releases/download/knative-v${KNATIVE_VERSION}/istio.yaml
    kubectl apply -f https://github.com/knative/net-istio/releases/download/knative-v${KNATIVE_VERSION}/istio.yaml
    kubectl apply -f https://github.com/knative/net-istio/releases/download/knative-v${KNATIVE_VERSION}/net-istio.yaml
else
    echo "✅ Istio already installed, configuring for Knative..."
    kubectl apply -f https://github.com/knative/net-istio/releases/download/knative-v${KNATIVE_VERSION}/net-istio.yaml
fi

# Configure Knative domain
echo "🌐 Configuring Knative domain..."
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"example.com":""}}'

echo "📦 Installing KServe..."

# Install KServe CRDs
kubectl apply -f https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve.yaml

# Wait for KServe controller to be ready
echo "⏳ Waiting for KServe controller to be ready..."
kubectl wait --for=condition=ready pod -l control-plane=kserve-controller-manager --timeout=300s -n kserve

# Install KServe built-in ClusterServingRuntimes
echo "📋 Installing KServe built-in serving runtimes..."
kubectl apply -f https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve-runtimes.yaml

# Create namespace for model serving
echo "📁 Creating model serving namespace..."
kubectl create namespace kserve-models || true

# Label namespace for Istio injection
kubectl label namespace kserve-models istio-injection=enabled --overwrite

# Create default storage configuration
echo "📋 Creating default storage configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: inferenceservice-config
  namespace: kserve
data:
  storageInitializer: |-
    {
        "image" : "kserve/storage-initializer:latest",
        "memoryRequest": "100Mi",
        "memoryLimit": "1Gi",
        "cpuRequest": "100m",
        "cpuLimit": "1"
    }
  credentials: |-
    {
       "gcs": {
           "gcsCredentialFileName": "gcloud-application-credentials.json"
       },
       "s3": {
           "s3AccessKeyIDName": "AWS_ACCESS_KEY_ID",
           "s3SecretAccessKeyName": "AWS_SECRET_ACCESS_KEY"
       }
    }
EOF

# Create a sample model storage secret for demo
echo "🔐 Creating sample storage configuration..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
  namespace: kserve-models
  annotations:
     serving.kserve.io/s3-endpoint: minio-service.kubeflow:9000
     serving.kserve.io/s3-usehttps: "0"
type: Opaque
data:
  AWS_ACCESS_KEY_ID: bWluaW8=
  AWS_SECRET_ACCESS_KEY: bWluaW8xMjM=
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kserve-sa
  namespace: kserve-models
secrets:
- name: mysecret
EOF

# Enable raw deployment mode (useful for development)
echo "🔧 Configuring KServe for development..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: inferenceservice-config
  namespace: kserve
data:
  deploy: |-
    {
      "defaultDeploymentMode": "RawDeployment"
    }
EOF

echo "🔍 Verifying KServe installation..."
kubectl get pods -n kserve
kubectl get pods -n knative-serving

echo "✅ KServe installation completed!"
echo ""
echo "🎯 KServe is ready for model serving!"
echo ""
echo "📋 Available ClusterServingRuntimes:"
kubectl get clusterservingruntimes
echo ""
echo "🔍 To deploy a model, create an InferenceService in the 'kserve-models' namespace"
echo "Example: kubectl apply -f model-deploy/inferenceservice.yaml"