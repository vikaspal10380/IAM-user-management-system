# ==============================================================================
# IAM MODULE — Input Variables
# ==============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "iam_users" {
  description = "Map of IAM users with group assignments and tags"
  type = map(object({
    group = string
    tags  = map(string)
  }))
}

variable "force_destroy_users" {
  description = "Allow force-destroy of IAM users"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
