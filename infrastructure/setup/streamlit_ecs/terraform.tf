terraform {
  required_version = "~> 1.0"

  # --- Backend must be provisioned first
  backend "s3" {
    bucket         = "tf-state-data-lake-717395713637"
    key            = "state_analytics/terraform.tfstate"
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
