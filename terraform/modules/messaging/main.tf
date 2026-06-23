# SQS Queue - Inventory
resource "aws_sqs_queue" "inventory" {
  name                       = "${var.project_name}-inventory-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "${var.project_name}-inventory-queue"
    Environment = var.environment
  }
}

# SQS Queue - Notification
resource "aws_sqs_queue" "notification" {
  name                       = "${var.project_name}-notification-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10

  tags = {
    Name        = "${var.project_name}-notification-queue"
    Environment = var.environment
  }
}

# SNS Topic
resource "aws_sns_topic" "orders" {
  name = "${var.project_name}-orders-topic"

  tags = {
    Name        = "${var.project_name}-orders-topic"
    Environment = var.environment
  }
}

# SNS → SQS Notification subscription
resource "aws_sns_topic_subscription" "notification" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification.arn
}

# SQS Policy - allow SNS to send messages
resource "aws_sqs_queue_policy" "notification" {
  queue_url = aws_sqs_queue.notification.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.notification.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.orders.arn
        }
      }
    }]
  })
}

# EventBridge Rule - order.created
resource "aws_cloudwatch_event_rule" "order_created" {
  name        = "${var.project_name}-order-created"
  description = "Fires when a new order is created"

  event_pattern = jsonencode({
    source      = ["orderflow.order-service"]
    detail-type = ["order.created"]
  })

  tags = {
    Name        = "${var.project_name}-order-created"
    Environment = var.environment
  }
}

# EventBridge → SQS Inventory target
resource "aws_cloudwatch_event_target" "inventory" {
  rule      = aws_cloudwatch_event_rule.order_created.name
  target_id = "inventory-queue"
  arn       = aws_sqs_queue.inventory.arn
}

# EventBridge → SNS target
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.order_created.name
  target_id = "orders-topic"
  arn       = aws_sns_topic.orders.arn
}

# SQS Policy - allow EventBridge to send to inventory queue
resource "aws_sqs_queue_policy" "inventory" {
  queue_url = aws_sqs_queue.inventory.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.inventory.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.order_created.arn
        }
      }
    }]
  })
}

# SNS Policy - allow EventBridge to publish
resource "aws_sns_topic_policy" "orders" {
  arn = aws_sns_topic.orders.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.orders.arn
    }]
  })
}