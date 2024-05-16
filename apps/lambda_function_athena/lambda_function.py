import logging
import os
import time

import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

ATHENA_REGION = os.getenv("ATHENA_REGION")
ATHENA_WORKGROUP = os.getenv("ATHENA_WORKGROUP")
ATHENA_OUTPUT_PATH = os.getenv("ATHENA_OUTPUT_PATH")


def lambda_handler(event, context):

    database_name = event["database_name"]
    query = event["query"]

    athena_client = boto3.client("athena")
    query_execution = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={
            "Database": database_name,
        },
        ResultConfiguration={
            "OutputLocation": ATHENA_OUTPUT_PATH,
        },
    )
    execution_id = query_execution["QueryExecutionId"]

    result = []
    state = ""
    while True:
        query_details = athena_client.get_query_execution(
            QueryExecutionId=execution_id
        )
        state = query_details["QueryExecution"]["Status"]["State"]
        logger.info(f"query_details: {query_details}")
        if state in ["SUCCEEDED", "FAILED", "CANCELLED"]:
            break
        time.sleep(0.5)
    if state == "SUCCEEDED":
        response_query_result = athena_client.get_query_results(
            QueryExecutionId=execution_id
        )
        columns = [
            col["Label"]
            for col in response_query_result["ResultSet"]["ResultSetMetadata"][
                "ColumnInfo"
            ]
        ]
        for res in response_query_result["ResultSet"]["Rows"][1:]:
            values = []
            for field in res["Data"]:
                try:
                    values.append(list(field.values())[0])
                except Exception as error:
                    logger.warning(error)
                    values.append(list(" "))
            result.append(dict(zip(columns, values)))

    return {"result": result, "state": state}


if __name__ == "__main__":
    import json

    lambda_client = boto3.client("lambda")
    event = {
        "database_name": "database_sor",
        "query": "SELECT * FROM database_sor.pokemon_dataset limit 10;",
    }
    response = lambda_client.invoke(
        FunctionName="athena_lambda",
        InvocationType="RequestResponse",
        Payload=json.dumps(event),
    )
    response_str = response["Payload"].read().decode("utf-8")
    response_dict = json.loads(response_str)
    print(response_dict)
