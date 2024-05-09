import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

REGION_NAME = os.getenv("REGION_NAME")
CRAWLER_NAME = os.getenv("CRAWLER_NAME")


glue = boto3.client(
    service_name="glue",
    region_name=REGION_NAME,
    endpoint_url=f"https://glue.{REGION_NAME}.amazonaws.com",
)


def lambda_handler(event, context):
    try:
        glue.start_crawler(Name=CRAWLER_NAME)
    except Exception as error:
        logger.error(f"Error starting crawler: {error}")
        raise error
