import os

import boto3

glue = boto3.client("glue")
sts_client = boto3.client("sts")
account_id = sts_client.get_caller_identity().get("Account")


glue.start_job_run(
    JobName="hello-world",
    Arguments={
        "dataset_slug": "jaidalmotra/pokemon-dataset",
        "s3_bucket_name": f"sor-{account_id}",
        "s3_prefix": "pokemon-dataset",
        "kaggle_username": os.getenv("KAGGLE_USERNAME"),
        "kaggle_key": os.getenv("KAGGLE_KEY"),
    },
)
