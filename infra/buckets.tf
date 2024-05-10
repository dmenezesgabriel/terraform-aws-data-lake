locals {
  buckets = {
    "sor" : {
      tags : { name : "sor-bucket" }
    },
    "sot" : {
      tags : { name : "sot-bucket" }
    },
    "spec" : {
      tags : { name : "spec-bucket" }
    },
  }
}

module "data_lake_bucket" {
  source = "./modules/bucket"

  for_each = local.buckets

  bucket_name = "${each.key}-${data.aws_caller_identity.current.account_id}"
  bucket_tags = {
    Name = each.value.tags.name
  }
}
