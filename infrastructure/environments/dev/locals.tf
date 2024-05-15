locals {
  apps_dir                            = abspath("${path.module}/../../../apps")
  lambda_function_duckdb_dir          = "${local.apps_dir}/lambda_function_duckdb"
  lambda_function_duckdb_requirements = "${local.lambda_function_duckdb_dir}/requirements.txt"
  duckdb_lambda_layer_path            = "${local.lambda_function_duckdb_dir}/layer"
  data_lake_layers = {
    "sor" : {
      tags : { name : "sor" }
    },
    "sot" : {
      tags : { name : "sot" }
    },
    "spec" : {
      tags : { name : "spec" }
    },
  }
}
