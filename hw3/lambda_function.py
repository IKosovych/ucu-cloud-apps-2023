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
            'message': 'Hello, world1!'
        }
        s3 = boto3.client('s3')
        bucket_name = 'my-first-bucket-ihor2'
        file_key = f'{request_id}.json'

        try:
            s3.put_object(
                Body=json.dumps(response),
                Bucket=bucket_name,
                Key=file_key
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
