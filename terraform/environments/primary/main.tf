terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

 backend "s3" {
  bucket = "orderflow-terraform-state-679"   # yeh update karo
  key    = "primary/terraform.tfstate"
  region = "us-east-1"
}
}

provider "aws" {
  region = var.aws_region
}

# ── Networking Module ─────────────────────────────────────────
module "networking" {
  source       = "../../modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

# ── ECS + ECR Module ──────────────────────────────────────────
module "ecs" {
  source = "../../modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.networking.alb_sg_id
  ecs_sg_id          = module.networking.ecs_sg_id
}