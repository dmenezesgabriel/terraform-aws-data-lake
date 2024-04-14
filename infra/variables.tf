variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Common tags you want applied to all resources"
  default = {
    Project = "data-lake-sdx"
  }
}

variable "bucket_list" {
  type    = list(string)
  default = ["sor", "sot", "spec"]
}
