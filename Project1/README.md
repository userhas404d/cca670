# CCA 670 - SageMaker

A terraform module to deploy a simple SageMaker example project

## PreReqs

1. terraform
2. collect credentials for, or create a new IAM identity (role or user) that has the required permissions necessary to deploy this module's resources.


## How to Deploy

1. Set the credentials for the target identity within your execution environment

2. Define the region in which these resources will be deployed via an environment variable: 

```bash
export AWS_DEFAULT_REGION=us-east-1
```

3. Run the necessary commands

```bash

terraform init
terraform plan
terraform apply
```

