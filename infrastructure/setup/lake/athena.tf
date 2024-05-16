locals {
  athena_query_results_bucket_name = "athena-query-results-${data.aws_caller_identity.current.account_id}"
  athena_users_workgroup_name      = "athena-users-workgroup"
}

resource "aws_s3_bucket" "athena_query_results" {
  bucket = local.athena_query_results_bucket_name
}

resource "aws_athena_workgroup" "athena_users_workgroup" {
  name = local.athena_users_workgroup_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/output/"
    }
  }
}
