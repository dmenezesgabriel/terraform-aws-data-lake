resource "aws_s3_bucket" "bucket" {
  for_each = toset(var.bucket_list)
  bucket   = "${each.key}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${each.key}-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "hello" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id

  key     = "hello.json"
  content = jsonencode({ name = "S3" })
}
