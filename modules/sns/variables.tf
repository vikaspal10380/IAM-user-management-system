# ==============================================================================
# SNS MODULE — Input Variables
# ==============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "alert_email" {
  description = "Email address for alert notifications (empty = skip subscription)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
