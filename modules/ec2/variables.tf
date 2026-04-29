# ==============================================================================
# EC2 MODULE — Input Variables
# ==============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group creation"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to the EC2 instance"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access (empty = no SSH)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
