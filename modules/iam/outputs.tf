# ==============================================================================
# IAM MODULE — Outputs
# ==============================================================================

output "user_arns" {
  description = "Map of IAM user names to their ARNs"
  value       = { for k, v in aws_iam_user.users : k => v.arn }
}

output "group_arns" {
  description = "Map of IAM group names to their ARNs"
  value = {
    AdminGroup   = aws_iam_group.admin.arn
    DevGroup     = aws_iam_group.dev.arn
    TesterGroup  = aws_iam_group.tester.arn
    BillingGroup = aws_iam_group.billing.arn
  }
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_access_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "billing_policy_arn" {
  description = "ARN of the custom billing policy"
  value       = aws_iam_policy.billing_access.arn
}

output "deny_billing_policy_arn" {
  description = "ARN of the deny billing policy"
  value       = aws_iam_policy.deny_billing.arn
}
