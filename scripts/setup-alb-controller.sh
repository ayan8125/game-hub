#!/bin/bash

##############################################################################
# Setup AWS Load Balancer Controller (IAM + ServiceAccount + Helm install)
##############################################################################

set -euo pipefail

CLUSTER_NAME="game-hub-cluster"
REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
ROLE_NAME="AmazonEKSLoadBalancerControllerRole"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
SERVICE_ACCOUNT_NAMESPACE="kube-system"
VPC_ID="vpc-08afea01d75da8238"   # change if needed

echo "📥 Downloading AWS Load Balancer Controller IAM policy..."
curl -sS -o iam_policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

echo "🛠 Ensuring IAM policy exists: ${POLICY_NAME}..."
if ! aws iam get-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME} >/dev/null 2>&1; then
  aws iam create-policy \
    --policy-name "${POLICY_NAME}" \
    --policy-document file://iam_policy.json
  echo "✅ IAM policy created."
else
  echo "ℹ️ IAM policy already exists, skipping creation."
fi

POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

echo "👤 Creating IAM ServiceAccount via eksctl (IRSA)..."
eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --namespace "${SERVICE_ACCOUNT_NAMESPACE}" \
  --name "${SERVICE_ACCOUNT_NAME}" \
  --role-name "${ROLE_NAME}" \
  --attach-policy-arn "${POLICY_ARN}" \
  --approve \
  --override-existing-serviceaccounts

echo "📦 Adding EKS Helm repo..."
helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
helm repo update eks

echo "🚀 Installing AWS Load Balancer Controller via Helm..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n "${SERVICE_ACCOUNT_NAMESPACE}" \
  --set clusterName="${CLUSTER_NAME}" \
  --set serviceAccount.create=false \
  --set serviceAccount.name="${SERVICE_ACCOUNT_NAME}" \
  --set region="${REGION}" \
  --set vpcId="${VPC_ID}"

echo "✅ Verifying deployment..."
kubectl get deployment -n "${SERVICE_ACCOUNT_NAMESPACE}" aws-load-balancer-controller

echo "✅ AWS Load Balancer Controller is installed and running."
