🎮 Game Hub — Flask Application on AWS EKS Fargate using ALB Ingress

This project deploys a Flask web application to Amazon EKS running on AWS Fargate, exposed using an AWS Application Load Balancer (ALB). The entire deployment uses Kubernetes manifests, IRSA, Helm, IAM, and CloudWatch logging.

The repo includes complete end-to-end setup steps to:

Build & push Docker image to ECR

Create EKS Fargate cluster

Configure IAM OIDC provider

Install AWS Load Balancer Controller

Deploy Kubernetes application resources

Expose application using ALB (Ingress)

Access application publicly via browser

🚀 Architecture Overview
User → Internet → AWS ALB → Target Groups → EKS Fargate Pods → Flask App → CloudWatch Logs


No EC2 worker nodes

Completely serverless workload

IAM-based pod authorization (IRSA)

ALB automatically managed via Kubernetes Ingress

🧰 Prerequisites

Install all required DevOps tooling.

Docker
```sudo apt-get update``` 
```sudo apt-get install -y docker.io```

kubectl
```curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client```

eksctl
```curl --silent --location \
  "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version```

Helm
```curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4```
```chmod 700 get_helm.sh```
```./get_helm.sh```

AWS CLI
```sudo apt-get install awscli```
```aws configure```

🟣 Push Application Image to Amazon ECR

Use a script to build & push image.

```aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com```

```docker build -t sample-game-app:latest ./app```
```docker tag sample-game-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/sample-game-app:latest```
```docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/sample-game-app:latest```

🟦 Create EKS Fargate Cluster
```eksctl create cluster \
  --name game-hub-cluster \
  --region us-east-1 \
  --fargate```

🔐 Configure IAM OIDC Provider (IRSA)
```eksctl utils associate-iam-oidc-provider \
  --cluster game-hub-cluster \
  --approve```

🟡 Create Fargate Profile
```eksctl create fargateprofile \
  --cluster game-hub-cluster \
  --region us-east-1 \
  --name alb-game-hub \
  --namespace game-hub```

🟠 Install AWS Load Balancer Controller
1. Download IAM policy
```curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json```

2. Create IAM policy
```aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json```

3. Create IAM Role + K8s ServiceAccount
```eksctl create iamserviceaccount \
  --cluster=game-hub-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve```

4. Install Helm chart
```helm repo add eks https://aws.github.io/eks-charts```
```helm repo update eks```

```helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=game-hub-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-08afea01d75da8238```

5. Verify controller
```kubectl get deployment -n kube-system aws-load-balancer-controller```

🧩 Deploy Kubernetes Application
Apply manifests
```kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml```

Verify pods
```kubectl get pods -n game-hub```

Verify service
```kubectl get svc -n game-hub```

Verify ingress
```kubectl get ingress -n game-hub```


Expected:

ADDRESS
```k8s-gamehub-xxxxx.us-east-1.elb.amazonaws.com```


Open in browser:

```http://k8s-gamehub-xxxxx.us-east-1.elb.amazonaws.com```


🎉 Your Flask game app should load.

🧪 Debug Commands
Check ALB targets
```aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN> ```

Check pod HTTP response
``` kubectl exec -it <pod-name> -n game-hub -- curl -I http://localhost:5000/ ```


Expected:

``` HTTP/1.1 200 OK ```

📁 Repository Structure (Recommended)
k8s-game-hub/
│
├─ app/                         # Flask app source code
├─ k8s/                         # Kubernetes manifests
│   ├─ namespace.yaml
│   ├─ deployment.yaml
│   ├─ service.yaml
│   ├─ ingress.yaml
│
├─ iam/                         # IAM JSON policies
│   ├─ iam_policy.json
│
├─ scripts/                     # Deployment automation scripts
│   ├─ push-ecr.sh
│
├─ images/                      # Screenshots, diagrams
├─ README.md
└─ prerequisites.md

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

📜 License

MIT
