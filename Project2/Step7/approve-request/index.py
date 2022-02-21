import boto3
import base64
import json
import os
import urllib3

import cfnresponse


def get_ssm_string(path):
    ssm_client = boto3.client("ssm")
    response = ssm_client.get_parameter(Name=path, WithDecryption=True)
    return response["Parameter"]["Value"]


# set global defaults``
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")
API_GW_ENDPOINT = os.getenv("API_GW_ENDPOINT")
if not API_GW_ENDPOINT:
    API_GW_ENDPOINT = get_ssm_string(os.getenv("SSM_API_GW_ENDPOINT"))


def send_sns_message(event):
    print("sending sns message..")
    stack_id = event["StackId"]
    # base64 encode the wait url to avoid having to worry about url interpolation
    wait_url = base64.b64encode(
        str.encode(event["ResourceProperties"]["WaitUrl"])
    ).decode()

    approve_url = f"{API_GW_ENDPOINT}?requestStatus=APPROVE&waitUrl={wait_url}"
    deny_url = f"{API_GW_ENDPOINT}?requestStatus=DENY&waitUrl={wait_url}"
    sns_message = f"""
    Hi Admin,

    A user has launched a stack {stack_id}

    Approve this action by clicking the following link: 

    {approve_url}

    Deny this action by clicking the following link:

    {deny_url}

    Please ignore if you do ont want the stack to be launched.
    
    Thank you,

    The Service Catalog Team
    """
    sns_client = boto3.client("sns")
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=sns_message,
        Subject=f"Approval request for {stack_id}"[
            0:100
        ],  # https://github.com/spulec/moto/issues/1503#issue-303369773
    )


def approve_request(wait_url):
    wait_url = base64.b64decode(str.encode(wait_url)).decode()
    print(f"submitting approval response via: {wait_url}")
    http = urllib3.PoolManager()

    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-waitcondition.html
    response_body = {
        "Status": "SUCCESS",
        "Reason": "Configuration Complete",
        "UniqueId": "ID1234",
        "Data": "Application has completed configuration.",
    }
    json_responseBody = json.dumps(response_body)

    print("Response body:")
    print(json_responseBody)

    headers = {"content-type": "", "content-length": str(len(json_responseBody))}

    try:
        response = http.request(
            "PUT", wait_url, headers=headers, body=json_responseBody
        )
        print(f"wait url response: {response.msg}")
        print(f"wait url response status code: {response.status}")

    except Exception as e:
        print("send(..) failed executing http.request(..):", e)


def handle_apigw_request(event):
    try:
        request_status = event["queryStringParameters"]["requestStatus"]
        wait_url = event["queryStringParameters"]["waitUrl"]
        if request_status == "APPROVE":
            approve_request(wait_url)
            response = {"data": "CFN operation has been approved"}
        elif request_status == "DENY":
            response = {"data": "CFN operation has been denied"}
        else:
            response = {"data": "Invalid request status provided."}
    except TypeError:
        response = {"data": "Invalid query string provided."}
    return {"statusCode": "200", "body": json.dumps(response)}


def handle_cfn_request(event, context):
    # send response to the cfn service
    responseValue = "CustomResource"
    responseData = {}
    responseData["Data"] = responseValue
    cfnresponse.send(
        event,
        context,
        cfnresponse.SUCCESS,
        responseData,
        os.getenv("AWS_LAMBDA_FUNCTION_NAME"),
    )


def lambda_handler(event, context):
    print(event)

    if event.get("httpMethod"):
        print("Handling api gateway request..")
        return handle_apigw_request(event)

    if event.get("ResourceProperties"):
        print("Handling cfn request..")

        # only send sns alert if the stack is being created
        if event["RequestType"] == "Create":
            send_sns_message(event)

        handle_cfn_request(event, context)
        return

    else:
        print(f"received unknown event type: {event}")
        return


if __name__ == "__main__":
    lambda_handler(
        {
            "StackId": "test123",
            "ResponseURL": "",
            "physicalResourceId": "123",
            "ResourceProperties": {"WaitUrl": "http://example.com", "Input": "1"},
        },
        {"log_stream_name": "123"},
    )
