import boto3
import os
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client("sns")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

table_name = os.environ.get('DDB_TABLE')
logging.info(f"## Loaded table name from environemt variable DDB_TABLE: {table_name}")

dynamodb_client = boto3.client('dynamodb')
dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table(table_name)
logging.info(f"## Initialized table")

def lambda_handler(event, context):
    logging.info(f"event: {event}")
    logging.info(f"routeKey: {event['routeKey']}")

    if event['routeKey'] == "DELETE /topmovies/{year}":
        year = int(event['pathParameters']['year'])
        query_result = table.delete_item(Key={ 'year': year })
        logging.info(f"query_result: {query_result}")
        body = {"message": f"deleted top movie for {year}"}

    elif event['routeKey'] == "GET /topmovies/{year}":
        year = int(event['pathParameters']['year'])
        query_result = table.get_item(Key={ 'year': year })
        logging.info(f"query_result: {query_result}")
        if "Item" in query_result.keys():
            item = query_result["Item"]
            body = {"year": int(item['year']), "title": item['title']}
        else:
            body = {"message": f"no top movie for {year}"}

    elif event['routeKey'] == "GET /topmovies":
        query_result = table.scan()
        logging.info(f"query_result: {query_result}")
        items = query_result["Items"]
        body = [{"year": int(item['year']), "title": item['title']} for item in items]

    elif event['routeKey'] == "PUT /topmovies":
        request_body = json.loads(event.get('body'))
        logging.info(f"request_body: {request_body}")
        year = int(request_body["year"])
        title = request_body["title"]
        query_result = table.put_item(Item={ "year": year, "title": title })
        logging.info(f"query_result: {query_result}")
        body = {"message": f"added top movie for {year}"}

        # SNS Email when DDD PUT is triggered
        message = f"INFO: DDB Put Triggered!"
        sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=message)
        logger.info(f"DDB Publish: {message}")

    else:
        body = {}

    logging.info(f"body: {body}")
    response_body = json.dumps(body)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": response_body
    }
