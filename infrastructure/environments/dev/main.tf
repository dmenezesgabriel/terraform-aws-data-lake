locals {
  apps_dir                                  = abspath("${path.module}/../../../apps")
  lambda_function_kaggle_to_s3_dir          = "${local.apps_dir}/kaggle_to_s3"
  lambda_function_kaggle_to_s3_requirements = "${local.lambda_function_kaggle_to_s3_dir}/requirements.txt"
  requests_lambda_layer_path                = "${local.lambda_function_kaggle_to_s3_dir}/layer"
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

# --- #
module "lambda_layers_bucket" {
  source      = "../../modules/bucket"
  bucket_name = "lambda-layers-${data.aws_caller_identity.current.account_id}"
}

resource "aws_iam_policy" "requests_lambda" {
  name = "requests_lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

resource "null_resource" "requests_lambda_layer" {
  triggers = {
    requirements = filesha1(local.lambda_function_kaggle_to_s3_requirements)
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -r ${local.requests_lambda_layer_path}/python
      mkdir -p ${local.requests_lambda_layer_path}/python
      pip3 install -r ${local.lambda_function_kaggle_to_s3_requirements} -t ${local.requests_lambda_layer_path}/python/
    EOT
  }
}


module "requests_lambda_layer" {
  source = "../../modules/lambda_layer"

  lambda_layer_name                        = "python_requests"
  lambda_layer_source_directory            = local.requests_lambda_layer_path
  lambda_layer_zip_file_output_path        = "${local.lambda_function_kaggle_to_s3_dir}/requests_lambda_layer.zip"
  lambda_layer_bucket_id                   = module.lambda_layers_bucket.bucket.id
  lambda_layer_version_compatible_runtimes = ["python3.11"]

  depends_on = [null_resource.requests_lambda_layer]
}

module "requests_lambda" {
  source                    = "../../modules/lambda"
  region                    = var.region
  function_policy_arn       = aws_iam_policy.requests_lambda.arn
  function_name             = "requests_lambda"
  function_handler          = "lambda_function.lambda_handler"
  function_layers           = [module.requests_lambda_layer.lambda_layer_version.arn]
  function_source_file_path = "${local.apps_dir}/kaggle_to_s3/lambda_function.py"
  function_zip_file_path    = "${local.apps_dir}/kaggle_to_s3/lambda_function.zip"
  function_runtime          = "python3.11"
  lambda_function_environment_variables = {
    REGION_NAME = var.region
  }
}
