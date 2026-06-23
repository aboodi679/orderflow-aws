output "inventory_queue_url" {
  value = aws_sqs_queue.inventory.url
}

output "inventory_queue_arn" {
  value = aws_sqs_queue.inventory.arn
}

output "notification_queue_url" {
  value = aws_sqs_queue.notification.url
}

output "orders_topic_arn" {
  value = aws_sns_topic.orders.arn
}

output "order_created_rule_arn" {
  value = aws_cloudwatch_event_rule.order_created.arn
}