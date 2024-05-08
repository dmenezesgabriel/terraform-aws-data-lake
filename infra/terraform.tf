terraform {
  required_version = "~> 1.0"

  # --- At first terraform init must comment this block
  #  backend "s3" {
  #    bucket         = "terraform-lake-state"
  #    key            = "state/terraform.tfstate"
  #    region         = "us-east-1"
  #    encrypt        = true
  #    kms_key_id     = "alias/terraform-bucket-key"
  #    dynamodb_table = "terraform-lake-state"
  #  }
  # --- At first terraform init must comment this block

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
