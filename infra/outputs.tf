output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

output "current_workspace_name" {
  value = terraform.workspace
}

output "bucket_names" {
  value = [for bucket in aws_s3_bucket.bucket : bucket.bucket]
}

output "crawler_trigger_lambda_names" {
  value = [for url in aws_lambda_function.crawler_trigger_lambda : url.function_name]
}

output "crawler_trigger_lambda_url" {
  value = [for url in aws_lambda_function_url.crawler_trigger_lambda : url.function_url]
}
