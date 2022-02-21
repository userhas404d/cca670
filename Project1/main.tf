locals {

  # define a map of tags that will be assigned to module resources by default
  default_tags = {
    "ManagedBy" : "Terraform"
    "ProjectName" : var.project_name
    "stage" : var.project_stage
  }

  resource_name_prefix = "${var.project_name}-${var.project_stage}-sagemaker"
}

# bucket
resource "aws_s3_bucket" "this" {
  bucket_prefix = "${local.resource_name_prefix}-"
  tags          = local.default_tags
}

# codecommit repository
# https://aws.amazon.com/blogs/publicsector/how-to-manage-amazon-sagemaker-code-aws-codecommit/
data "aws_codecommit_repository" "this" {
  repository_name = var.codecommit_repository_name
}

# iam
resource "aws_iam_role" "this" {
  name_prefix = "${local.resource_name_prefix}-execution-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "sagemaker-execution-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : [
            aws_s3_bucket.this.arn
          ]
        },
        {
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${aws_s3_bucket.this.arn}/*"
          ]
        },
        {
          "Sid" : "SagemakerRepoFullAccess",
          "Effect" : "Allow",
          "Action" : "codecommit:*",
          "Resource" : data.aws_codecommit_repository.this.arn
        }
      ]
    })
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"]

  tags = local.default_tags
}

# notebook instance
resource "aws_sagemaker_notebook_instance" "this" {
  name = local.resource_name_prefix

  role_arn      = aws_iam_role.this.arn
  instance_type = var.sagemaker_notebook_instance_type
  volume_size   = var.sagemaker_notebook_volume_size

  default_code_repository = data.aws_codecommit_repository.this.clone_url_http
  platform_identifier     = "notebook-al2-v1" # https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-al2.html

  tags = local.default_tags
}