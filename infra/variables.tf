variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "bucket_list" {
  type    = list(string)
  default = ["sor", "sot", "spec"]
}

variable "lambda_policy_arn" {
  description = "ARN of the IAM role policy to attach to the lambda role."
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
