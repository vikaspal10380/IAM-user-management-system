# ==============================================================================
# SNS MODULE — Alert Notifications (Bonus Feature)
# Sends notifications for security events detected by CloudWatch alarms
# ==============================================================================

# ------------------------------------------------------------------------------
# SNS TOPIC — Central notification channel for security alerts
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "security_alerts" {
  name         = "${var.project_name}-security-alerts"
  display_name = "IAM Management System - Security Alerts"

  # Enable server-side encryption for the topic
  kms_master_key_id = "alias/aws/sns"

  tags = merge(var.common_tags, {
    Purpose = "Security alert notifications"
  })
}

# ------------------------------------------------------------------------------
# SNS TOPIC POLICY — Restrict who can publish to the topic
# Only CloudWatch and CloudTrail services can publish alerts
# ------------------------------------------------------------------------------

resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      },
      {
        Sid    = "AllowCloudTrailPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# SNS EMAIL SUBSCRIPTION — Send alerts to the specified email
# Note: The email recipient must confirm the subscription manually
# ------------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "email_alert" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
