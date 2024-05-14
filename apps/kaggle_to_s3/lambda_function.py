import requests


def lambda_handler(event, context):
    return {"message": requests.__version__}
