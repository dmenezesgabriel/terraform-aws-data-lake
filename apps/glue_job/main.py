import os
import sys
from zipfile import ZipFile

import boto3
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from kaggle.api.kaggle_api_extended import KaggleApi
from pyspark.context import SparkContext

sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()

# Get resolved options
args = getResolvedOptions(
    sys.argv,
    [
        "dataset_slug",
        "s3_bucket_name",
        "s3_prefix",
        "kaggle_username",
        "kaggle_key",
    ],
)
dataset_slug = args["dataset_slug"]
s3_bucket_name = args["s3_bucket_name"]
s3_prefix = args["s3_prefix"]

os.environ["KAGGLE_USERNAME"] = args["kaggle_username"]
os.environ["KAGGLE_KEY"] = args["kaggle_key"]

logger.info(os.environ)


api = KaggleApi()
api.authenticate()

s3_client = boto3.client("s3")


def upload_to_s3(file_path, s3_key):
    with open(file_path, "rb") as file:
        s3_client.upload_fileobj(file, s3_bucket_name, s3_key)


def download_dataset_and_upload():
    api.dataset_download_files(dataset_slug)

    with ZipFile(f"{dataset_slug.split('/')[1]}.zip", "r") as zip_ref:
        zip_ref.extractall("data")

    for file in os.listdir("data"):
        if os.path.isfile(os.path.join("data", file)):
            upload_to_s3(os.path.join("data", file), s3_prefix + file)


def main():
    download_dataset_and_upload()


if __name__ == "__main__":
    main()
