terraform {
  required_version = "~> 1.0"

  # --- Backend must be provisioned first
  backend "s3" {
    bucket         = "tf-state-data-lake-717395713637"
    key            = "state_streamlit_ecs_image/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-data-lake-717395713637"
    encrypt        = false
    # kms_key_id     = ""
  }
  # --- Backend must be provisioned first

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}

locals {
  apps_dir = abspath("${path.module}/../../../apps")
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "main" {
  name                 = "streamlit_analytics"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.ecr_repository_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "push_analytics_docker_image" {
  source = "../../modules/push_image"

  region                      = var.region
  ecr_repository_name         = aws_ecr_repository.main.name
  ecr_registry_uri            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  container_image_tag         = "latest"
  container_image_source_path = "${local.apps_dir}/streamlit_ecs"
  force_image_rebuild         = false
}
