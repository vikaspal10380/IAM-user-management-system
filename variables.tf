# ==============================================================================
# ROOT VARIABLES — IAM User Management System
# All configurable parameters for the entire infrastructure
# ==============================================================================

variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  default     = "iam-mgmt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# ------------------------------------------------------------------------------
# IAM Configuration
# ------------------------------------------------------------------------------

variable "iam_users" {
  description = "Map of IAM users to create with their group assignments"
  type = map(object({
    group = string
    tags  = map(string)
  }))
  default = {
    admin_user = {
      group = "AdminGroup"
      tags  = { Role = "Administrator" }
    }
    dev_user = {
      group = "DevGroup"
      tags  = { Role = "Developer" }
    }
    tester_user = {
      group = "TesterGroup"
      tags  = { Role = "Tester" }
    }
    billing_user = {
      group = "BillingGroup"
      tags  = { Role = "BillingManager" }
    }
  }
}

variable "force_destroy_users" {
  description = "Allow destroying IAM users even if they have non-Terraform-managed access keys, MFA devices, etc."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# EC2 Configuration
# ------------------------------------------------------------------------------

variable "ec2_instance_type" {
  description = "EC2 instance type for the demo instance"
  type        = string
  default     = "t2.micro"
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instance (leave empty to use latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "ec2_key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access (leave empty to skip)"
  type        = string
  default     = ""
}

variable "ec2_vpc_id" {
  description = "VPC ID for EC2 instance (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "ec2_subnet_id" {
  description = "Subnet ID for EC2 instance (leave empty to use default subnet)"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# S3 Configuration
# ------------------------------------------------------------------------------

variable "audit_bucket_name" {
  description = "S3 bucket name for CloudTrail audit logs"
  type        = string
  default     = "iam-audit-logs-bucket"
}

variable "s3_force_destroy" {
  description = "Allow Terraform to destroy the S3 bucket even if it contains objects"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# CloudTrail Configuration
# ------------------------------------------------------------------------------

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "iam-audit-trail"
}

# ------------------------------------------------------------------------------
# CloudWatch Configuration
# ------------------------------------------------------------------------------

variable "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
  default     = "IAM-Monitoring-Dashboard"
}

# ------------------------------------------------------------------------------
# SNS Configuration (Bonus)
# ------------------------------------------------------------------------------

variable "enable_sns_alerts" {
  description = "Enable SNS alerts for suspicious activity"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for SNS alert notifications"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Common Tags
# ------------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "IAM-User-Management-System"
    ManagedBy   = "Terraform"
    Environment = "prod"
  }
}
