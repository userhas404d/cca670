output "bucket" {
  value       = aws_s3_bucket.this
  description = "The bucket created for this module"
}

output "role" {
  value       = aws_iam_role.this
  description = "The IAM role associated with the sagemaker instance"
}

output "sagemaker_notebook_instance" {
  value       = aws_sagemaker_notebook_instance.this
  description = "The sagemaker notebook instance resource"
}