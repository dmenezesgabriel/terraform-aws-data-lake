variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "bucket_list" {
  type    = list(string)
  default = ["sor", "sot", "spec"]
}
