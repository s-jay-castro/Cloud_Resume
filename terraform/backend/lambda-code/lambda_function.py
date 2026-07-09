# Handles the passing of the environment variable or access to the OS memory
import os
# Handles the processing of the JSON files
import json
# Handles the AWS integration
import boto3

# DYNAMODB_DB environment variable passed from terraform to allow modularity and dynamics
TABLE_NAME = os.environ['DYNAMODB_TABLE']

# Initialize the DynamoDB resource
dynamodb = boto3.resource('dynamodb')
# Set table as an instance of dynamodb using the TABLE_NAME assigned from the value passed from the environment variable
table = dynamodb.Table(TABLE_NAME)

# Function needs to have event and context parameters. Ensure that function name is the same in the terraform file
# where the API is created and the handler key is set.
def lambda_handler(event, context):
    # Use update_item to increment the 'VisitorCount' attribute atomically
    response = table.update_item(
        Key={'id': 'counter'},
        UpdateExpression='ADD VisitorCount :inc',
        ExpressionAttributeValues={':inc': 1},
        ReturnValues='UPDATED_NEW'
    )
    # Response is a table of values or dictionary since ReturnValues was set to return updated data

    # Extract the new count by searching using the keys Attributes and VisitorCount
    new_count = response['Attributes']['VisitorCount']

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',  # Required to prevent frontend CORS blocks
            'Access-Control-Allow-Methods': '*',
            'Access-Control-Allow-Headers': '*'
        },
        # json.dumps converts the Python dictionary into a clean JSON text string for your JavaScript
        'body': json.dumps({'count': int(new_count)})
    }