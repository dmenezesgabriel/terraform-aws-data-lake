variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Project environment"
  type        = string
}

variable "bucket_list" {
  description = "Bucket names list"
  type        = list(string)
}

variable "bucket_tags" {
  type = object({
    Name = string
  })
}

variable "lambda_policy_arn" {
  description = "ARN of the IAM role policy to attach to the lambda role."
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

variable "enable_s3_object_created_trigger_crawler" {
  description = "Enable s3_object_created_trigger_crawler"
  type        = bool
}
