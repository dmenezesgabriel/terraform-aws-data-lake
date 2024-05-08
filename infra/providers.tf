provider "aws" {
  region = var.region
  default_tags {

    tags = {
      Enviroment = "DEVELOPMENT"
      Project    = "data-lake-sdx"
    }
  }
}
