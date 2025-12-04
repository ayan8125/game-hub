🎮 Game Hub — Flask Application on AWS EKS Fargate using ALB Ingress

<img width="1920" height="1080" alt="game-1" src="https://github.com/user-attachments/assets/bf7aa005-918d-4498-a247-1beb0021c5de" />


This project deploys a Flask web application to Amazon EKS running on AWS Fargate, exposed using an AWS Application Load Balancer (ALB). The entire deployment uses Kubernetes manifests, IRSA, Helm, and IAM.

- The repo includes complete end-to-end setup steps to:

  - ### Build & push Docker image to ECR

  - ### Create EKS Fargate cluster

  - ### Configure IAM OIDC provider

  - ### Install AWS Load Balancer Controller

  - ### Deploy Kubernetes application resources

  - ### Expose application using ALB (Ingress)

  - ### Access application publicly via browser

## 🚀 Architecture Overview

Conceptual Kubernetes view:

User → Internet → Ingress → Service → Pods → Flask App

Actual AWS EKS + ALB data path:

User → Internet → AWS ALB → Target Group (IP mode) → EKS Fargate Pods → Flask App

- No EC2 worker nodes

- Completely serverless workload

- IAM-based pod authorization (IRSA)

- ALB automatically managed via Kubernetes Ingress

🧰 Prerequisites

Install all required DevOps tooling.

Docker
```
sudo apt-get update
```

```
sudo apt-get install -y docker.io
```

kubectl
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

eksctl
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
```
```
sudo mv /tmp/eksctl /usr/local/bin
```
```
eksctl version
```

Helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
```

```
chmod 700 get_helm.sh
```

```
./get_helm.sh
```

AWS CLI
```
sudo apt-get install awscli
```
```
aws configure
```
You will be prompted to enter four values:
```
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxxxx
AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Default region name [None]: us-east-1
Default output format [None]: json
```
Your credentials will be stored in:

  - ~/.aws/credentials

  - ~/.aws/config

### Verify Your Configuration

```
Verify Your Configuration
```

Expected output:
```
{
    "UserId": "xxxxxxxxxxxx",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

## AWS IAM Permissions Required

To use this project safely, certain AWS IAM permissions must be granted to your IAM User.
These permissions ensure that the AWS CLI commands used in this project work without errors.

### 1. Required AWS Managed Policies

Attach the following AWS-managed policies to your IAM User:

```
AmazonEC2ContainerRegistryPowerUser
AmazonEC2FullAccess
AWSCloudFormationFullAccess
IAMFullAccess
```

### 2. Custom IAM Policy Included in This Repository

This repository includes a custom IAM policy to allow additional actions required by this project.

The policy file is located at:

```
game-hub/iam/EksAllAccess.json
```
### How to attach the custom policy

  1. Go to AWS IAM → Policies

  2. Click Create Policy

  3. Switch to the JSON tab

  4. Copy the contents from:
      ``` game-hub/iam/EksAllAccess.json ```
  5. Click Next → Next → Create Policy
  6. Attach the newly created policy to your IAM User.


## 🟣 Push Application Image to Amazon ECR

Use a script to build & push image.

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

```
docker build -t sample-game-app:latest ./app 
# Update the path to match your environment:
# For EC2, the correct path is usually: /home/ubuntu/game-hub/app
```
```
docker tag sample-game-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/sample-game-app:latest
```
```
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/sample-game-app:latest
```

## 🟦 Create EKS Cluster
```
eksctl create cluster --name game-hub-cluster --region us-east-1 --fargate
```

## 🟦 Create Fargate profile

```
eksctl create fargateprofile \
    --cluster game-hub-cluster \
    --region us-east-1 \
    --name alb-game-hub \
    --namespace game-hub
```

## 🟦 Deploy the deployment, service and Ingress




🔐 Configure IAM OIDC Provider

```
oidc_id=$(aws eks describe-cluster --name game-hub-cluster --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5) 
```

```
eksctl utils associate-iam-oidc-provider \
  --cluster game-hub-cluster \
  --approve
```



🟡 Create Fargate Profile
```
eksctl create fargateprofile \
  --cluster game-hub-cluster \
  --region us-east-1 \
  --name alb-game-hub \
  --namespace game-hub
```

🟠 Install AWS Load Balancer Controller
1. Download IAM policy
```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```

3. Create IAM policy
```
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

3. Create IAM Role + K8s ServiceAccount
```
eksctl create iamserviceaccount \
  --cluster=game-hub-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

4. Install Helm chart
```
helm repo add eks https://aws.github.io/eks-charts
```
```
helm repo update eks
```

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=game-hub-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<region> \
  --set vpcId=<cluster-vpc-id>
```

5. Verify controller
```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

🧩 Deploy Kubernetes Application
Apply manifests
```
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

Verify pods
```
kubectl get pods -n game-hub
```

Verify service
```
kubectl get svc -n game-hub
```

Verify ingress
```
kubectl get ingress -n game-hub
```


Expected:

ADDRESS
```k8s-gamehub-xxxxx.us-east-1.elb.amazonaws.com```


Open in browser:

```http://k8s-gamehub-xxxxx.us-east-1.elb.amazonaws.com```


🎉 Your Flask game app should load.

🧪 Debug Commands
Check ALB targets
```
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN>
```

Check pod HTTP response
``` 
kubectl exec -it <pod-name> -n game-hub -- curl -I http://localhost:5000/
```
Expected:

``` HTTP/1.1 200 OK ```

🟢 Notes

Kubernetes pods run entirely on AWS Fargate (serverless)

No EC2 node groups required

IAM is handled via IRSA

ALB is automatically created by Kubernetes Ingress

DNS uses AWS Load Balancer DNS hostname

🧠 Future Enhancements

✔ CloudWatch Fluent Bit deployment

✔ HTTPS using ACM + alb.ingress.kubernetes.io/certificate-arn

✔ Helm chart for app deployment

✔ ECR image versioning via Git commit tags

✔ Terraform version of cluster setup

