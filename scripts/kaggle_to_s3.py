import logging
import os
from pathlib import Path
from zipfile import ZipFile

logger = logging.getLogger()
logger.setLevel(logging.INFO)

import boto3
from kaggle.api.kaggle_api_extended import KaggleApi


def upload_to_s3(file_path, s3_bucket_name, s3_key):
    with open(file_path, "rb") as file:
        s3_client = boto3.client("s3")
        s3_client.upload_fileobj(file, s3_bucket_name, s3_key)


def download_dataset_and_upload(dataset_slug, s3_bucket_name, s3_prefix):
    api = KaggleApi()
    api.authenticate()
    api.dataset_download_files(dataset_slug)

    with ZipFile(f"{dataset_slug.split('/')[1]}.zip", "r") as zip_ref:
        zip_ref.extractall("data")

    for file in os.listdir("data"):
        logger.info(f"Uploading file: {file}")
        if os.path.isfile(os.path.join("data", file)):
            file_path = os.path.join("data", file)
            file_name = Path(file).stem
            s3_key = os.path.join(s3_prefix, file_name, file)
            upload_to_s3(
                file_path,
                s3_bucket_name,
                s3_key,
            )


if __name__ == "__main__":
    sts_client = boto3.client("sts")
    account_id = sts_client.get_caller_identity().get("Account")
    dataset_slug = "rishabjadhav/imdb-actors-and-movies"
    s3_bucket_name = f"sor-{account_id}"
    s3_prefix = dataset_slug.split("/")[1]
    download_dataset_and_upload(dataset_slug, s3_bucket_name, s3_prefix)
