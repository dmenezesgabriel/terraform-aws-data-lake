import boto3
import duckdb


def lambda_handler(event, context):
    query = event["query"]
    conn = duckdb.connect(":memory:")
    conn.execute("SET home_directory='/tmp';INSTALL httpfs;LOAD httpfs;")
    result = conn.sql(query)
    records = result.fetchall()
    column_names = result.columns
    result = [
        {column_names[index]: row[index] for index in range(len(column_names))}
        for row in records
    ]
    return {"result": result}


if __name__ == "__main__":
    import json

    lambda_client = boto3.client("lambda")
    sts_client = boto3.client("sts")
    account_id = sts_client.get_caller_identity().get("Account")

    query = f"""
    SELECT
      *
    FROM read_csv('s3://sor-{account_id}/fifa/fifa18_clean.csv')
    LIMIT 5;
    """

    event = {"query": query}
    response = lambda_client.invoke(
        FunctionName="duckdb_lambda",
        InvocationType="RequestResponse",
        Payload=json.dumps(event),
    )
    response_str = response["Payload"].read().decode("utf-8")
    response_dict = json.loads(response_str)
    print(response_dict)
