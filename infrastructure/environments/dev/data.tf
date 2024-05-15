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

data "aws_iam_policy_document" "duckdb_lambda" {
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
    effect    = "Allow"
    resources = [for module in module.data_lake_bucket : "${module.bucket.arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
  }
}
