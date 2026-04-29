# ==============================================================================
# S3 MODULE — Input Variables
# ==============================================================================

variable "bucket_name" {
  description = "Name for the S3 audit log bucket"
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to destroy bucket even with objects inside"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region (used for CloudTrail ARN in bucket policy)"
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail (used for bucket policy)"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain audit logs before deletion"
  type        = number
  default     = 365
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
