# ==============================================================================
# CLOUDWATCH MODULE — Input Variables
# ==============================================================================

variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for dashboard widgets"
  type        = string
}

variable "account_id" {
  description = "AWS account ID for dashboard display"
  type        = string
}

variable "ec2_instance_id" {
  description = "EC2 instance ID for metrics widgets"
  type        = string
}

variable "cloudtrail_log_group_name" {
  description = "CloudTrail CloudWatch log group name for log insights queries"
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for security events"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications (empty = no notifications)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
