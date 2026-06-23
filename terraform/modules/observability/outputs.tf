output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "xray_group_arn" {
  value = aws_xray_group.main.arn
}