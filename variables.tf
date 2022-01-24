variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "project_stage" {
  type        = string
  description = "The stage of the project ie. Dev, Test, Production"
}

variable "sagemaker_notebook_instance_type" {
  type        = string
  default     = "ml.t2.medium"
  description = "The instance type to assign to the sagemaker notebook instance"
}

variable "sagemaker_notebook_volume_size" {
  type        = string
  default     = "5"
  description = "The size, in GB, of the ML storage volume to attach to the notebook instance."
}

variable "codecommit_repository_name" {
  type        = string
  description = "The name of the codecommit repository to associate with the sagemaker instance."
}