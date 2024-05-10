locals {
  database_name   = "database"
  connection_name = "athena_Connection"
}

resource "aws_glue_catalog_database" "catalog" {
  for_each = module.data_lake_bucket
  name     = "${local.database_name}_${each.key}"

  tags = {
    Name = "glue-catalog-${each.key}"
  }
}

resource "aws_glue_crawler" "crawler" {
  for_each      = module.data_lake_bucket
  name          = "${each.key}_crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.catalog[each.key].name

  s3_target {
    path = each.value.bucket.bucket
  }

  tags = {
    Name = "${each.key}_glue_crawler"
  }
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "datalake_glue_crawler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "glue_crawler_policy" {
  name = "datalake_glue_crawler_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "glue:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:/aws-glue/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_crawler_policy_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_policy.arn
}
