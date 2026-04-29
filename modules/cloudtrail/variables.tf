# ==============================================================================
# CLOUDTRAIL MODULE — Input Variables
# ==============================================================================

variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for storing CloudTrail logs"
  type        = string
}

variable "s3_bucket_policy_dependency" {
  description = "Dependency to ensure S3 bucket policy is created before CloudTrail"
  type        = any
  default     = null
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 90
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
