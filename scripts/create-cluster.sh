#!/bin/bash

##############################################################################
# Create EKS Fargate cluster + Fargate profile + OIDC provider
##############################################################################

set -euo pipefail

CLUSTER_NAME="game-hub-cluster"
REGION="us-east-1"
NAMESPACE="game-hub"
FARGATE_PROFILE_NAME="alb-game-hub"

echo "🚀 Creating EKS Fargate cluster: ${CLUSTER_NAME} in ${REGION}..."
eksctl create cluster \
  --name "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --fargate

echo "🔐 Associating IAM OIDC provider (IRSA)..."
eksctl utils associate-iam-oidc-provider \
  --cluster "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --approve

echo "📦 Creating Fargate profile: ${FARGATE_PROFILE_NAME} for namespace: ${NAMESPACE}..."
eksctl create fargateprofile \
  --cluster "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --name "${FARGATE_PROFILE_NAME}" \
  --namespace "${NAMESPACE}"

echo "✅ Cluster + OIDC + Fargate profile ready."
