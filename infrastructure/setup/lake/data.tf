data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3_object_created_trigger_crawler" {

  for_each = local.data_lake_layers

  version = "2012-10-17"
  statement {
    effect    = "Allow"
    resources = ["${module.data_lake_bucket[each.key].bucket.arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
  }

  statement {
    effect    = "Allow"
    resources = [aws_glue_crawler.crawler[each.key].arn]

    actions = [
      "glue:StartCrawler",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }

}

data "aws_iam_policy_document" "lambda_s3_access" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    resources = [for module in module.data_lake_bucket : "${module.bucket.arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

data "aws_iam_policy_document" "glue_job" {
  statement {
    effect = "Allow"
    resources = concat(
      flatten([for module in module.data_lake_bucket : "${module.bucket.arn}/*"]),
      ["${module.glue_assets_bucket.bucket.arn}/*"]
    )

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

data "aws_iam_policy_document" "lambda_athena_access" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    resources = [
      "*",
    ]

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:CreateBucket",
      "s3:PutObject"
    ]
  }
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetDataCatalog",
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetTables"
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

data "aws_cognito_user_pools" "main" {
  name = "analytics_user_pool"
}

data "external" "user_pool_client_by_user_pool_id" {
  program = ["bash", "-c", "aws cognito-idp list-user-pool-clients --user-pool-id '${data.aws_cognito_user_pools.main.ids[0]}' --query 'UserPoolClients[?ClientName==`${var.cognito_user_pool_client_name}`] | [0]' --output json"]
}
