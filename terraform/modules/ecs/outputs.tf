output "ecr_repository_urls" {
  value = {
    for k, v in aws_ecr_repository.services : k => v.repository_url
  }
  description = "ECR URLs for pushing Docker images"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS — services yahan accessible honge"
}