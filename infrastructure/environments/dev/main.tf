module "data_lake_bucket" {
  for_each = local.data_lake_layers

  source      = "../../modules/bucket"
  bucket_name = "${each.key}-${data.aws_caller_identity.current.account_id}"
}

module "lambda_layers_bucket" {
  source      = "../../modules/bucket"
  bucket_name = "lambda-layers-${data.aws_caller_identity.current.account_id}"
}

module "glue_assets_bucket" {
  source      = "../../modules/bucket"
  bucket_name = "glue-assets-${data.aws_caller_identity.current.account_id}"
}

module "s3_object_created_trigger_crawler" {
  for_each = var.enable_s3_object_created_trigger_crawler ? local.data_lake_layers : {}

  source                    = "../../modules/lambda"
  region                    = var.region
  function_policy_json      = data.aws_iam_policy_document.s3_object_created_trigger_crawler[each.key].json
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


resource "null_resource" "duckdb_lambda_layer" {
  triggers = {
    requirements = filesha1(local.lambda_function_duckdb_requirements)
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -r ${local.duckdb_lambda_layer_path}/python
      mkdir -p ${local.duckdb_lambda_layer_path}/python
      pip3 install -r ${local.lambda_function_duckdb_requirements} -t ${local.duckdb_lambda_layer_path}/python/
    EOT
  }
}


module "duckdb_lambda_layer" {
  source = "../../modules/lambda_layer"

  lambda_layer_name                        = "python_duckdb"
  lambda_layer_source_directory            = local.duckdb_lambda_layer_path
  lambda_layer_zip_file_output_path        = "${local.lambda_function_duckdb_dir}/duckdb_lambda_layer.zip"
  lambda_layer_bucket_id                   = module.lambda_layers_bucket.bucket.id
  lambda_layer_version_compatible_runtimes = ["python3.11"]

  depends_on = [null_resource.duckdb_lambda_layer]
}

module "duckdb_lambda" {
  source = "../../modules/lambda"

  region                    = var.region
  function_policy_json      = data.aws_iam_policy_document.lambda_s3_access.json
  function_name             = "duckdb_lambda"
  function_handler          = "lambda_function.lambda_handler"
  function_layers           = [module.duckdb_lambda_layer.lambda_layer_version.arn]
  function_source_file_path = "${local.apps_dir}/lambda_function_duckdb/lambda_function.py"
  function_zip_file_path    = "${local.apps_dir}/lambda_function_duckdb/lambda_function.zip"
  function_runtime          = "python3.11"
  function_memory_size      = 128
  function_timeout          = 15
  lambda_function_environment_variables = {
    REGION_NAME = var.region
  }
}

module "athena_lambda" {
  source = "../../modules/lambda"

  region                    = var.region
  function_policy_json      = data.aws_iam_policy_document.lambda_athena_access.json
  function_name             = "athena_lambda"
  function_handler          = "lambda_function.lambda_handler"
  function_source_file_path = "${local.apps_dir}/lambda_function_athena/lambda_function.py"
  function_zip_file_path    = "${local.apps_dir}/lambda_function_athena/lambda_function.zip"
  function_runtime          = "python3.11"
  function_memory_size      = 128
  function_timeout          = 15
  lambda_function_environment_variables = {
    ATHENA_REGION      = var.region
    ATHENA_WORKGROUP   = aws_athena_workgroup.athena_users_workgroup.name
    ATHENA_OUTPUT_PATH = "s3://${aws_s3_bucket.athena_query_results.bucket}"
  }
}

resource "aws_lambda_permission" "athena_lambda_allow_apigateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.athena_lambda.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
}

module "api_gateway" {
  source                    = "../../modules/api_gateway"
  api_gateway_name          = "analytics_api"
  api_gateway_stage         = "dev"
  api_gateway_protocol_type = "HTTP"
  api_gateway_body = templatefile("${local.apps_dir}/analytics_api/api.yaml",
    {
      athena_lambda_arn = "${module.athena_lambda.lambda_function.invoke_arn}"
      aws_region        = var.region
    }
  )
}

# module "hello_glue_job" {
#   source = "../../modules/glue_job"

#   region                            = var.region
#   glue_job_policy_json              = data.aws_iam_policy_document.glue_job.json
#   glue_job_name                     = "hello-world"
#   glue_job_bucket                   = module.glue_assets_bucket.bucket.bucket
#   glue_job_source_file_path         = "${local.apps_dir}/glue_job/main.py"
#   glue_job_aditional_python_modules = "kaggle==1.6.3"
# }

# #
# resource "aws_ecr_repository" "lambda_container_ecr_repository" {
#   name                 = "lambda_container"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }


# module "push_lambda_container_docker_image" {
#   source = "../../modules/push_image"

#   region                      = var.region
#   ecr_repository_name         = aws_ecr_repository.lambda_container_ecr_repository.name
#   ecr_registry_uri            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
#   container_image_tag         = "latest"
#   container_image_source_path = "${local.apps_dir}/lambda_container"
#   force_image_rebuild         = false
# }

# module "lambda_container" {
#   source = "../../modules/lambda_container"

#   region               = var.region
#   function_image_uri   = "${aws_ecr_repository.lambda_container_ecr_repository.repository_url}:latest"
#   function_policy_json = data.aws_iam_policy_document.lambda_s3_access.json
#   function_name        = "lambda_container"
#   function_memory_size = 128
#   function_timeout     = 15
#   lambda_function_environment_variables = {
#     REGION_NAME = var.region
#   }
# }
