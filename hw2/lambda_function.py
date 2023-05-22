import json
import boto3


def lambda_handler(event, context):
    try:
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
            'message': 'Hello, world!'
        }
        s3 = boto3.client('s3')
        bucket_name = 'my-first-bucket-ihor2'  # Replace with your S3 bucket name
        file_key = f'{request_id}.json'  # Set the desired file key (path) for the JSON file

        s3.put_object(
            Body=json.dumps(response),
            Bucket=bucket_name,
            Key=file_key
        )

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
