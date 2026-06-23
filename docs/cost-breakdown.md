# Cost Breakdown

## Estimated Monthly Cost

| Service | Configuration | Est. Cost/month |
|---|---|---|
| ECS Fargate | 3 tasks × 0.25 vCPU × 0.5 GB | ~$8–10 |
| ALB | 1 load balancer | ~$8 |
| ECR | 3 repositories, ~150 MB images | ~$0.50 |
| SQS | Standard queues, low volume | ~$0.50 |
| SNS | Standard topic, low volume | ~$0.10 |
| EventBridge | Custom rules, low volume | ~$0.10 |
| CloudWatch | Dashboard + 5 alarms + logs | ~$2–3 |
| X-Ray | 5% sampling rate | ~$0.50 |
| **Total** | | **~$20–25/month** |

---

## Cost Optimization Decisions

### No NAT Gateway
ECS tasks run in public subnets with `assign_public_ip = true` instead of private subnets with a NAT Gateway. NAT Gateway costs ~$32/month alone — eliminated entirely.

### No RDS
DynamoDB on-demand pricing means zero cost when idle. RDS MySQL (even db.t3.micro) costs ~$15/month regardless of usage.

### Minimal Fargate sizing
Each task runs at 0.25 vCPU and 512 MB RAM — the minimum Fargate configuration. Sufficient for a demo workload, easily scaled up via Terraform variable change.

### ECR lifecycle policies
Each ECR repository has a lifecycle policy keeping only the last 3 images — prevents storage costs from accumulating with every CI/CD push.

---

## Saving Tips

### Destroy when not in use

```bash
terraform destroy
```

Eliminates ~$18/month of Fargate + ALB costs. ECR images, SQS queues, and EventBridge rules remain (near-zero cost at rest).

### Redeploy anytime

```bash
terraform apply
```

Full infrastructure back up in under 5 minutes.

