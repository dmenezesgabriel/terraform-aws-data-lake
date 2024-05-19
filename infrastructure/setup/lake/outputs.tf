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
  value = [for module in module.data_lake_bucket : module.bucket.bucket]
}

output "crawler_trigger_lambda_names" {
  value = [for function in module.s3_object_created_trigger_crawler : function.lambda_function.function_name]
}

output "user_pool_client_id" {
  value = data.external.user_pool_client_by_user_pool_id.result.ClientId
}

