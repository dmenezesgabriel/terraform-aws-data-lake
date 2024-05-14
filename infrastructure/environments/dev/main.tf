locals {
  apps_dir = abspath("${path.module}/../../../apps")
  data_lake_layers = {
    "sor" : {
      tags : { name : "sor" }
    },
    "sot" : {
      tags : { name : "sot" }
    },
    "spec" : {
      tags : { name : "spec" }
    },
  }
}

module "data_lake_bucket" {
  for_each = local.data_lake_layers

  source      = "../../modules/bucket"
  bucket_name = "${each.key}-${data.aws_caller_identity.current.account_id}"
  bucket_tags = {
    Name = each.value.tags.name
  }
}

resource "aws_iam_policy" "s3_object_created_trigger_crawler" {
  for_each = local.data_lake_layers

  name = "s3_object_created_trigger_crawler_${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:CopyObject",
          "s3:HeadObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "glue:StartCrawler",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

module "s3_object_created_trigger_crawler" {
  for_each = var.enable_s3_object_created_trigger_crawler ? local.data_lake_layers : {}

  source                    = "../../modules/lambda"
  region                    = var.region
  function_policy_arn       = aws_iam_policy.s3_object_created_trigger_crawler[each.key].arn
  function_name             = "s3_object_created_trigger_crawler_${each.key}"
  function_handler          = "lambda_function.lambda_handler"
  function_source_file_path = "${local.apps_dir}/s3_object_created_trigger_crawler/lambda_function.py"
  function_zip_file_path    = "${local.apps_dir}/s3_object_created_trigger_crawler/lambda_function.zip"
  function_runtime          = "python3.11"
  lambda_function_environment_variables = {
    REGION_NAME  = var.region
    CRAWLER_NAME = "${each.key}_crawler"
  }
}

resource "aws_lambda_permission" "s3_object_created_trigger_crawler" {
  for_each = var.enable_s3_object_created_trigger_crawler ? module.data_lake_bucket : {}

  statement_id  = "AllowExecutionFromS3Bucket_${each.value.bucket.id}"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_object_created_trigger_crawler[each.key].lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = each.value.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  for_each = var.enable_s3_object_created_trigger_crawler ? module.data_lake_bucket : {}


  bucket = each.value.bucket.id
  lambda_function {
    lambda_function_arn = module.s3_object_created_trigger_crawler[each.key].lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.s3_object_created_trigger_crawler]
}
