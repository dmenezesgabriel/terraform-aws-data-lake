import json

from faker import Faker

fake = Faker()


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "profile": {
                    "name": fake.name(),
                    "address": fake.address(),
                },
            }
        ),
    }
