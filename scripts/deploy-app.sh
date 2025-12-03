#!/bin/bash

##############################################################################
# Deploy Kubernetes manifests for Game Hub app
##############################################################################

set -euo pipefail

NAMESPACE="game-hub"
K8S_DIR="k8s"

echo "📦 Applying namespace..."
kubectl apply -f "${K8S_DIR}/namespace.yaml"

echo "🚀 Deploying application (deployment, service, ingress)..."
kubectl apply -f "${K8S_DIR}/deployment.yaml"
kubectl apply -f "${K8S_DIR}/service.yaml"
kubectl apply -f "${K8S_DIR}/ingress.yaml"

echo "⏳ Waiting for pods to be ready..."
kubectl get pods -n "${NAMESPACE}"

echo "🌐 Getting Ingress details..."
kubectl get ingress -n "${NAMESPACE}"

echo "✅ Deployment finished. Copy the ADDRESS (ALB DNS) and open in your browser."
