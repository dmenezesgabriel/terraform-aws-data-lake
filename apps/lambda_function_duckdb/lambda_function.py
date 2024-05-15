import duckdb


def lambda_handler(event, context):
    return {"message": duckdb.__version__}
