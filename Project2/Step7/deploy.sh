#!/bin/bash

# A unique name to assign the cfn stack
STACK_NAME="approval-workflow"
# the email address to associate with the SNS topic
EMAIL=""
# the bucket where sam will place your lambda resources
S3_BUCKET=""


echo "STACK_NAME: $STACK_NAME"
echo "EMAIL: $EMAIL"
echo "S3_BUCKET: $S3_BUCKET"

echo "=============================================="
echo "Packaging the approval workflow resources cfn template.."
echo "=============================================="

# bundle the cfn template that contains the approval workflow resources
aws cloudformation package\
  --template-file ./approval.yml\
  --s3-bucket "$S3_BUCKET"\
  --output-template-file ./approval-packaged.yml

echo "=============================================="
echo "deploying the approval workflow resources cfn template.."
echo "=============================================="

# deploy the packaged cfn template generated in the previous step
aws cloudformation deploy\
 --template-file ./approval-packaged.yml\
 --s3-bucket "$S3_BUCKET"\
 --stack-name "$STACK_NAME"\
 --capabilities CAPABILITY_NAMED_IAM\
 --parameter-overrides pEmailAddress="$EMAIL"

# capture the ARN of the lambda function that will process cfn waitcondition requests
SNSNotificationLambdaArn=$(aws cloudformation describe-stacks\
 --stack-name "$STACK_NAME"\
 --query "Stacks[0].Outputs[?OutputKey=='oSNSNotificationLambda'].OutputValue"\
 --output text)

echo "=============================================="
echo "SNSNotificationLambdaArn: $SNSNotificationLambdaArn"
echo "=============================================="

echo "=============================================="
echo "check the inbox of $EMAIL for the SNS subscription email."
echo "Once you have subscribed: "
read -n1 -s -r -p $'Press space to continue...\n' key
echo "=============================================="

echo "=============================================="
echo "deploying a cfn stack that requires approval"
echo "check the inbox of $EMAIL to find the approval url."
echo "=============================================="

# deploy the stack that requires an approval prior to deployment
aws cloudformation deploy\
 --template-file ./ec2_approval_template.yml\
 --stack-name "$STACK_NAME-ec2"\
 --capabilities CAPABILITY_NAMED_IAM\
 --parameter-overrides\
  pNotificationLambdaFunctionArn=$SNSNotificationLambdaArn

echo "=============================================="
echo "deployment workflow complete. You can now manually delete the cfn stacks that were deployed."
echo "=============================================="
