# Deployment Guide

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| AWS CLI | >= 2.0 | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Terraform | >= 1.6.0 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Docker | >= 24.0 | [docker.com](https://www.docker.com/products/docker-desktop/) |
| Python | >= 3.11 | [python.org](https://www.python.org/downloads/) |

---

## Step 1 — AWS Configuration

```bash
aws configure
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region name: us-east-1
# Default output format: json
```

Verify:

```bash
aws sts get-caller-identity
```

---

## Step 2 — Clone the Repository

```bash
git clone https://github.com/aboodi679/orderflow-aws.git
cd orderflow-aws
```

---

## Step 3 — Deploy Infrastructure

```bash
cd terraform/environments/primary
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. Full deployment takes approximately 3-5 minutes.

Resources created:
- VPC + subnets + route tables + security groups
- ECS cluster + task definitions + services
- ECR repositories
- ALB + target groups + listener rules
- SQS queues + SNS topic + EventBridge rule
- CloudWatch dashboard + alarms + X-Ray group

---

## Step 4 — Build and Push Docker Images

For each service:

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin 026243800492.dkr.ecr.us-east-1.amazonaws.com

# Build and push order-service
docker build -t orderflow-order-service services/order-service/
docker tag orderflow-order-service:latest \
  026243800492.dkr.ecr.us-east-1.amazonaws.com/orderflow-order-service:latest
docker push \
  026243800492.dkr.ecr.us-east-1.amazonaws.com/orderflow-order-service:latest

# Repeat for inventory-service and notification-service
```

---

## Step 5 — Verify Deployment

Check ECS services are running:

```bash
aws ecs describe-services \
  --cluster orderflow-cluster \
  --services orderflow-order-service orderflow-inventory-service orderflow-notification-service \
  --region us-east-1 \
  --query "services[*].{Name:serviceName,Running:runningCount,Desired:desiredCount}"
```

Expected output:
```json
[
  { "Name": "orderflow-order-service",       "Running": 1, "Desired": 1 },
  { "Name": "orderflow-inventory-service",   "Running": 1, "Desired": 1 },
  { "Name": "orderflow-notification-service","Running": 1, "Desired": 1 }
]
```

Test the live endpoint:

```bash
curl http://orderflow-alb-1358729812.us-east-1.elb.amazonaws.com/health
# {"service":"order-service","status":"healthy"}
```

---

## Step 6 — GitHub Actions CI/CD Setup

### Create OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create IAM Role

Create `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_USERNAME>/orderflow-aws:*"
        }
      }
    }
  ]
}
```

```bash
aws iam create-role \
  --role-name orderflow-github-actions-role \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name orderflow-github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-role-policy \
  --role-name orderflow-github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
```

Now push any change to `services/order-service/` — the pipeline triggers automatically.

---

## Tear Down

```bash
cd terraform/environments/primary
terraform destroy
```

> Always destroy when not in use to avoid unnecessary AWS charges.

