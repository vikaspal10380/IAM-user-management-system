# ==============================================================================
# ROOT OUTPUTS — IAM User Management System
# Exposes key information from all modules for operational use
# ==============================================================================

# ------------------------------------------------------------------------------
# IAM Outputs
# ------------------------------------------------------------------------------

output "iam_user_arns" {
  description = "ARNs of all created IAM users"
  value       = module.iam.user_arns
}

output "iam_group_arns" {
  description = "ARNs of all IAM groups"
  value       = module.iam.group_arns
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = module.iam.ec2_instance_profile_arn
}

output "billing_policy_arn" {
  description = "ARN of the custom billing policy"
  value       = module.iam.billing_policy_arn
}

# ------------------------------------------------------------------------------
# S3 Outputs
# ------------------------------------------------------------------------------

output "audit_bucket_id" {
  description = "ID of the S3 audit log bucket"
  value       = module.s3.bucket_id
}

output "audit_bucket_arn" {
  description = "ARN of the S3 audit log bucket"
  value       = module.s3.bucket_arn
}

# ------------------------------------------------------------------------------
# CloudTrail Outputs
# ------------------------------------------------------------------------------

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.cloudtrail.trail_arn
}

output "cloudtrail_log_group" {
  description = "CloudWatch log group name for CloudTrail"
  value       = module.cloudtrail.cloudwatch_log_group_name
}

# ------------------------------------------------------------------------------
# EC2 Outputs
# ------------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "ID of the demo EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  description = "Private IP of the demo EC2 instance"
  value       = module.ec2.private_ip
}

output "ec2_public_ip" {
  description = "Public IP of the demo EC2 instance (if assigned)"
  value       = module.ec2.public_ip
}

# ------------------------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------------------------

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch monitoring dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.cloudwatch_dashboard_name}"
}

# ------------------------------------------------------------------------------
# SNS Outputs (Bonus)
# ------------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "ARN of the SNS security alerts topic"
  value       = var.enable_sns_alerts ? module.sns[0].topic_arn : "SNS alerts disabled"
}

# ------------------------------------------------------------------------------
# Summary Output — Quick reference for verification
# ------------------------------------------------------------------------------

output "deployment_summary" {
  description = "Summary of the deployed IAM management system"
  value = <<-SUMMARY
    ╔══════════════════════════════════════════════════════════════════╗
    ║           IAM User Management System — Deployment Summary       ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║  USERS CREATED:                                                  ║
    ║    • admin_user   → AdminGroup   (Full Access)                   ║
    ║    • dev_user     → DevGroup     (EC2 Full + S3 ReadOnly)        ║
    ║    • tester_user  → TesterGroup  (ReadOnly)                      ║
    ║    • billing_user → BillingGroup (Billing Only)                  ║
    ║                                                                  ║
    ║  EC2 INSTANCE:                                                   ║
    ║    • Instance ID: ${module.ec2.instance_id}
    ║    • IAM Role: EC2_Access_Role (S3 Read + CloudWatch Logs)       ║
    ║    • No static credentials — uses instance profile               ║
    ║                                                                  ║
    ║  AUDITING:                                                       ║
    ║    • CloudTrail: Multi-region, log validation enabled            ║
    ║    • S3 Bucket: ${module.s3.bucket_id} (encrypted)
    ║    • CloudWatch: Dashboard + Security Alarms                     ║
    ║                                                                  ║
    ║  SECURITY:                                                       ║
    ║    • Least privilege enforced                                     ║
    ║    • Billing access restricted to BillingGroup                   ║
    ║    • S3 public access blocked                                    ║
    ║    • IMDSv2 enforced on EC2                                      ║
    ║    • Encryption enabled on all storage                           ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
  SUMMARY
}
