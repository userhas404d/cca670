# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

from __future__ import print_function
import urllib3
import json

SUCCESS = "SUCCESS"
FAILED = "FAILED"

http = urllib3.PoolManager()


def send(
    event,
    context,
    responseStatus,
    responseData,
    physicalResourceId=None,
    noEcho=False,
    reason="",
):
    responseUrl = event["ResponseURL"]

    print(f"responseUrl: {responseUrl}")

    responseBody = {
        "Status": responseStatus,
        "Reason": reason,
        "PhysicalResourceId": physicalResourceId,
        "StackId": event.get("StackId"),
        "RequestId": event.get("RequestId"),
        "LogicalResourceId": event.get("LogicalResourceId"),
        "NoEcho": noEcho,
        "Data": responseData,
    }

    json_responseBody = json.dumps(responseBody)

    print(f"Response body: {json_responseBody}")

    headers = {"content-type": "", "content-length": str(len(json_responseBody))}

    try:
        response = http.request(
            "PUT", responseUrl, headers=headers, body=json_responseBody
        )
        print(f"cfn response message: {response.msg}")
        print(f"cfn response status code: {response.status}")

    except Exception as e:

        print("send(..) failed executing http.request(..):", e)
