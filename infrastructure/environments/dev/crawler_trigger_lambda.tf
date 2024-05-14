# locals {
#   crawler_trigger_function_file_name = "lambda_function"
#   cralwer_trigger_function_name      = "crawler_trigger_lambda"
#   cralwer_trigger_function_path      = "crawler_trigger_lambda"
#   cralwer_trigger_lambda_file_path   = "${abspath("${path.module}/../../../apps")}/${local.cralwer_trigger_function_path}/${local.crawler_trigger_function_file_name}"
# }

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "iam_for_crawler_trigger_function" {
#   name               = "iam_lambda_${local.cralwer_trigger_function_name}"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "s3_lambda_policy" {
#   role       = aws_iam_role.iam_for_crawler_trigger_function.name
#   policy_arn = var.lambda_policy_arn

# }

# resource "aws_iam_policy" "cralwer_trigger_function_bucket_access" {
#   name = "policy_${local.cralwer_trigger_function_name}"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "s3:ListBucket",
#           "s3:GetObject",
#           "s3:CopyObject",
#           "s3:HeadObject"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "glue:StartCrawler",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cralwer_trigger_function_bucket_access" {
#   role       = aws_iam_role.iam_for_crawler_trigger_function.name
#   policy_arn = aws_iam_policy.cralwer_trigger_function_bucket_access.arn

# }

# data "archive_file" "crawler_trigger_lambda" {
#   type        = "zip"
#   source_file = "${local.cralwer_trigger_lambda_file_path}.py"
#   output_path = "${local.cralwer_trigger_lambda_file_path}.zip"
# }

# resource "aws_lambda_function_url" "crawler_trigger_lambda" {
#   for_each = aws_lambda_function.crawler_trigger_lambda

#   function_name      = each.value.function_name
#   authorization_type = "NONE"
# }

# resource "aws_lambda_function" "crawler_trigger_lambda" {
#   for_each = module.data_lake_bucket

#   filename         = "${local.cralwer_trigger_lambda_file_path}.zip"
#   function_name    = "${each.key}_${local.cralwer_trigger_function_name}"
#   handler          = "lambda_function.lambda_handler"
#   role             = aws_iam_role.iam_for_crawler_trigger_function.arn
#   runtime          = "python3.11"
#   memory_size      = 128
#   timeout          = 3
#   source_code_hash = data.archive_file.crawler_trigger_lambda.output_base64sha256

#   ephemeral_storage {
#     size = 512
#   }

#   environment {
#     variables = {
#       REGION_NAME  = var.region
#       CRAWLER_NAME = "${each.key}_crawler"
#     }
#   }

#   tracing_config {
#     mode = "Active"
#   }
# }

# resource "aws_cloudwatch_log_group" "lambda_function" {
#   for_each = aws_lambda_function.crawler_trigger_lambda

#   name              = "/aws/lambda/${each.value.function_name}"
#   retention_in_days = 30
# }

# resource "aws_lambda_permission" "allow_bucket_trigger" {
#   for_each = module.data_lake_bucket

#   statement_id  = "AllowExecutionFromS3Bucket_${each.value.bucket.id}"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.crawler_trigger_lambda[each.key].function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = each.value.bucket.arn
# }

# resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
#   for_each = module.data_lake_bucket

#   bucket = each.value.bucket.id
#   lambda_function {
#     lambda_function_arn = aws_lambda_function.crawler_trigger_lambda[each.key].arn
#     events              = ["s3:ObjectCreated:*"]
#   }
#   depends_on = [aws_lambda_permission.allow_bucket_trigger]
# }
