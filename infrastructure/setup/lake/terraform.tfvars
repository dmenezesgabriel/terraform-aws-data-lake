region                                   = "us-east-1"
bucket_list                              = ["sor", "sot", "spec"]
environment                              = "dev"
enable_s3_object_created_trigger_crawler = false
bucket_tags = {
  Name = "S3 buckets"
}
cognito_user_pool_client_name = "analytics_user_pool_client"
cognito_user_pool_name        = "analytics_user_pool"
