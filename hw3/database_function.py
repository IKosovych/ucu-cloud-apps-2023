import json
import boto3


def lambda_handler(event, context):
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('my-table')
        print(event)
        headers = event['headers']
        request_id = headers.get('request-id')
        print(request_id)
        if not request_id:
            return {
                'statusCode': 400,
                'body': 'Missing request-id header'
            }

        response = {
            'request-id': request_id,
            'message': 'Hello, world3!'
        }
        try:
            table.put_item(
                Item={
                    'id': request_id,
                    'message': 'Hello, world3!'
                }
            )
        except Exception as e:
            print(e)
            response['message'] = str(e)

        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': 'Error processing the event'
        }
