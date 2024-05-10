provider "aws" {
  region = var.region
  default_tags {

    tags = {
      Project = "data-lake-sdx"
    }
  }
}
