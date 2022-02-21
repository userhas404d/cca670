# CCA670 Project 2 Step 7

This project re-implements the cfn templates that are no longer available via the [How to create an approval flow for an AWS Service Catalog product launch using AWS Lambda](https://aws.amazon.com/blogs/apn/how-to-create-an-approval-flow-for-an-aws-service-catalog-product-launch-using-aws-lambda/?nc1=b_rp) blog post.

## Prereqs

This project:

- assumes you are using linux, 
- have the latest version of the [aws cli installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), 
- and have [configured your cli environment](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) with an IAM identity that has the necessary permissions required to deploy the underlying resources.

## Deployment instructions

Update the following lines in `deploy.sh` with your implementation specific configuration: 

```bash
# A unique name to assign the cfn stack
STACK_NAME="approval-workflow"
# the email address to associate with the SNS topic
EMAIL=""
# the bucket where sam will place your lambda resources
S3_BUCKET=""
```

Then, from this project's directory run: 

```bash
./deploy.sh
```