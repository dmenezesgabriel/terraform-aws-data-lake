terraform {
  required_version = "~> 1.0"

  # --- Backend must be provisioned first
  backend "s3" {}
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

resource "aws_cognito_user_pool" "main" {
  name = "analytics_user_pool"

  email_verification_subject = "Your Verification Code"
  email_verification_message = "Please use the following code: {####}"
  alias_attributes           = ["email"]
  auto_verified_attributes   = ["email"]

  password_policy {
    minimum_length    = 6
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 7
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = true

    string_attribute_constraints {
      min_length = 3
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  user_pool_id = aws_cognito_user_pool.main.id
  domain       = "analytics-platform"
}

resource "aws_cognito_user_pool_client" "main" {
  name                = "analytics_user_pool_client"
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  user_pool_id        = aws_cognito_user_pool.main.id

  supported_identity_providers = [
    "COGNITO",
  ]

  callback_urls                        = var.identity_provider_callback_urls
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid"]
}
