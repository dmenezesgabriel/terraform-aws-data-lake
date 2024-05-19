output "cognito_login_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com/login?response_type=code&client_id=${aws_cognito_user_pool_client.main.id}&redirect_uri=${var.default_callback_url}"
}
