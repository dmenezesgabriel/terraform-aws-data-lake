from diagrams import Cluster, Diagram, Edge
from diagrams.aws.analytics import Athena, GlueCrawlers, GlueDataCatalog
from diagrams.aws.compute import LambdaFunction
from diagrams.aws.storage import S3
from diagrams.programming.flowchart import StartEnd


def create_data_catalog_layer():
    with Cluster("Data Catalog"):
        glue_data_catalog = GlueDataCatalog("AWS Glue Catalog")
        glue_crawler = GlueCrawlers("AWS Glue Crawler")
    return glue_data_catalog, glue_crawler


def create_data_lake_layer(bucket_name):
    with Cluster(bucket_name):
        bucket = S3(bucket_name)
        lambda_function_name = f"{bucket_name.lower()}_glue_trigger"
        lambda_function = LambdaFunction(lambda_function_name)
        s3_object_created_event = StartEnd("s3:ObjectCreated Event")
        glue_data_catalog, glue_crawler = create_data_catalog_layer()

    return (
        bucket,
        glue_data_catalog,
        glue_crawler,
        lambda_function,
        s3_object_created_event,
    )


graph_attr = {
    "fontsize": "45",
    "ranksep": "1",
}

with Diagram("Data Lake", graph_attr=graph_attr, direction="LR"):
    athena = Athena("Amazon Athena")
    duckdb_lambda = LambdaFunction(label="DuckDB Lambda")
    trigger_lambda = Edge(label="trigger lambda")
    run_glue_crawler = Edge(label="run glue crawler")

    buckets = []
    bucket_names = ["SOR", "SOT", "SPEC"]
    bucket_names.reverse()
    with Cluster(""):
        for bucket_name in bucket_names:
            (
                bucket,
                glue_data_catalog,
                glue_crawler,
                lambda_function,
                s3_object_created_event,
            ) = create_data_lake_layer(bucket_name)
            buckets.append(bucket)

            athena >> glue_data_catalog >> glue_crawler >> bucket
            (
                bucket
                >> s3_object_created_event
                >> trigger_lambda
                >> lambda_function
                >> run_glue_crawler
                >> glue_crawler
                >> glue_data_catalog
            )
    athena >> buckets
    duckdb_lambda >> buckets
