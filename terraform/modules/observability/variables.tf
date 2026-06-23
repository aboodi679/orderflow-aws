variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for CloudWatch metrics"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}