#!/bin/bash

##############################################################################
# Push Flask Game App Docker image to Amazon ECR
#
# Requirements:
#   - AWS CLI configured (aws configure)
#   - Docker installed
#   - AWS IAM user/role with ECR permissions
##############################################################################

set -e

#########################
# CONFIGURATION
#########################

AWS_REGION="us-east-1"                # <-- change if using another region
IMAGE_NAME="development/game-hub"           # <-- name of your app (used for ECR repo)
TAG="version1"                           # <-- choose specific tag later (recommended)

#########################
# GET AWS ACCOUNT ID
#########################

echo "🔍 Getting AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✔ AWS Account: ${ACCOUNT_ID}"

ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"

#########################
# CREATE ECR REPO (if not exists)
#########################

echo "🛠 Checking if ECR repo exists..."
aws ecr describe-repositories --repository-names "${IMAGE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1 || \
aws ecr create-repository --repository-name "${IMAGE_NAME}" --region "${AWS_REGION}"

echo "✔ ECR repo ready: ${ECR_REPO}"

#########################
# LOGIN TO ECR
#########################

echo "🔐 Logging into Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} \
| docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

#########################
# BUILD DOCKER IMAGE
#########################

echo "🐳 Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} ./app

#########################
# TAG IMAGE FOR ECR
#########################

echo "🏷 Tagging image for ECR..."
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REPO}:${TAG}

#########################
# PUSH IMAGE TO ECR
#########################

echo "📤 Pushing image to ECR..."
docker push ${ECR_REPO}:${TAG}

#########################
# DONE
#########################

echo "🎉 SUCCESS! Image pushed to ECR."
echo "👉 ECR Image URL:"
echo "${ECR_REPO}:${TAG}"
echo " "
echo "➡ Use this image in your Kubernetes deployment.yaml"
echo ""
echo "    image: ${ECR_REPO}:${TAG}"
echo ""
