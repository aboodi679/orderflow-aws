# Architecture

## Overview

OrderFlow is built on a microservices architecture deployed on AWS ECS Fargate. Services communicate asynchronously via an event-driven messaging layer using Amazon EventBridge, SQS, and SNS. All infrastructure is provisioned with modular Terraform — zero manual console interaction.

---

## Design Decisions

### Why ECS Fargate over Lambda?

Lambda is ideal for short-lived, stateless functions. OrderFlow services are long-running HTTP servers with persistent connections to ALB target groups — Fargate is the right fit. It also gives full container control without managing EC2 instances.

### Why EventBridge over direct SQS publish?

EventBridge acts as the central event bus. The order-service fires a single `order.created` event — EventBridge routes it to multiple targets (inventory queue + SNS topic) without the producer knowing about consumers. This decouples services completely.

### Why SNS between EventBridge and notification-queue?

SNS enables fan-out. If we add an email, SMS, or webhook notification target later, we only add an SNS subscription — zero changes to the order-service or EventBridge rule.

### Why modular Terraform?

Each module (networking, ecs, messaging, observability) is independently reusable. The `environments/primary` folder just calls modules with variables — adding a DR region means a new `environments/dr` folder calling the same modules.

---

## Component Breakdown

### Networking Module

```
VPC (10.0.0.0/16)
├── Public Subnet 1 (10.0.0.0/24) — us-east-1a
├── Public Subnet 2 (10.0.1.0/24) — us-east-1b
├── Private Subnet 1 (10.0.10.0/24) — us-east-1a
├── Private Subnet 2 (10.0.11.0/24) — us-east-1b
├── Internet Gateway
├── Public Route Table (0.0.0.0/0 → IGW)
├── ALB Security Group (inbound 80 from 0.0.0.0/0)
└── ECS Security Group (inbound 5000-5002 from ALB SG only)
```

### ECS Module

```
ECS Cluster (orderflow-cluster)
├── ECR Repository × 3 (one per service)
├── Task Definition × 3 (256 CPU, 512 MB RAM each)
├── ECS Service × 3 (desired count: 1, public subnets, assign public IP)
├── ALB (orderflow-alb)
│   ├── Listener (port 80)
│   ├── Target Group × 3
│   └── Listener Rules (path-based routing)
├── IAM Execution Role (AmazonECSTaskExecutionRolePolicy)
└── CloudWatch Log Groups × 3
```

### Messaging Module

```
EventBridge Rule (orderflow-order-created)
├── Source: orderflow.order-service
├── DetailType: order.created
├── Target 1: SQS inventory-queue (direct)
└── Target 2: SNS orders-topic
              └── Subscription: SQS notification-queue
```

### Observability Module

```
CloudWatch Dashboard (orderflow-dashboard)
├── ECS CPU Utilization (3 services)
├── ECS Memory Utilization (3 services)
├── ALB Request Count
├── ALB Target Response Time
├── SQS Inventory Queue messages
└── SQS Notification Queue messages

CloudWatch Alarms
├── ECS CPU > 80% × 3 services
├── SQS inventory queue depth > 100
└── SQS notification queue depth > 100

X-Ray
├── Group: orderflow-group
└── Sampling Rule: 5% fixed rate
```

---

## Security

- ECS tasks run in public subnets with `assign_public_ip = true` — required for ECR pull without NAT Gateway (cost optimization)
- ECS Security Group only allows inbound traffic from ALB Security Group — never from the internet directly
- IAM roles follow least-privilege — ECS execution role has only `AmazonECSTaskExecutionRolePolicy`
- GitHub Actions uses OIDC — no AWS access keys stored anywhere
- SQS queue policies restrict `sqs:SendMessage` to EventBridge and SNS only

---

## Scalability

The architecture is designed to scale horizontally:

- ECS services can increase `desired_count` or enable auto-scaling based on ALB request count
- SQS queues decouple producers from consumers — inventory and notification services can scale independently
- EventBridge fan-out means adding a new consumer requires zero changes to existing services
- Modular Terraform means adding a second region is a new environment folder — same modules

