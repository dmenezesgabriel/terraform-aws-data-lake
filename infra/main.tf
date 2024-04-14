resource "aws_s3_bucket" "bucket" {
  for_each = toset(var.bucket_list)
  bucket   = "${each.key}-${data.aws_caller_identity.current.account_id}"

  tags = var.common_tags
}
