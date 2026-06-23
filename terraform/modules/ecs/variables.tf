variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from networking module"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for ALB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for ECS tasks"
}

variable "alb_sg_id" {
  type        = string
  description = "ALB Security Group ID"
}

variable "ecs_sg_id" {
  type        = string
  description = "ECS Security Group ID"
}