resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "ECS CPU Utilization"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-order-service"],
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-inventory-service"],
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-notification-service"]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ECS Memory Utilization"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-order-service"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-inventory-service"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-notification-service"]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ALB Response Time"
          region = var.aws_region
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "SQS Inventory Queue"
          region = var.aws_region
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.project_name}-inventory-queue"],
            ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${var.project_name}-inventory-queue"]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "SQS Notification Queue"
          region = var.aws_region
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.project_name}-notification-queue"],
            ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${var.project_name}-notification-queue"]
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = toset(["order-service", "inventory-service", "notification-service"])

  alarm_name          = "${var.project_name}-${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU above 80%"

  dimensions = {
    ClusterName = "${var.project_name}-cluster"
    ServiceName = "${var.project_name}-${each.key}"
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  for_each = toset(["inventory", "notification"])

  alarm_name          = "${var.project_name}-${each.key}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "SQS queue depth above 100"

  dimensions = {
    QueueName = "${var.project_name}-${each.key}-queue"
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-queue-alarm"
    Environment = var.environment
  }
}

resource "aws_xray_group" "main" {
  group_name        = "${var.project_name}-group"
  filter_expression = "service(\"${var.project_name}\")"

  tags = {
    Name        = "${var.project_name}-xray-group"
    Environment = var.environment
  }
}

resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${var.project_name}-sampling"
  priority       = 1000
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
  version        = 1

  tags = {
    Name        = "${var.project_name}-sampling"
    Environment = var.environment
  }
}