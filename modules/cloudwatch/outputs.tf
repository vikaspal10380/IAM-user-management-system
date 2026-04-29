# ==============================================================================
# CLOUDWATCH MODULE — Outputs
# ==============================================================================

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value = {
    ec2_cpu_high = aws_cloudwatch_metric_alarm.ec2_cpu_high.arn
    unauthorized = var.enable_alarms ? aws_cloudwatch_metric_alarm.unauthorized_api_calls[0].arn : null
    root_usage   = var.enable_alarms ? aws_cloudwatch_metric_alarm.root_account_usage[0].arn : null
    iam_changes  = var.enable_alarms ? aws_cloudwatch_metric_alarm.iam_policy_changes[0].arn : null
  }
}
