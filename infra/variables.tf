variable "region" {
  description = "AWS region"
  type        = string
}

variable "bucket_list" {
  description = "Bucket names list"
  type        = list(string)
}

variable "lambda_policy_arn" {
  description = "ARN of the IAM role policy to attach to the lambda role."
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
