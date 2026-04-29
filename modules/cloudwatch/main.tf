# ==============================================================================
# CLOUDWATCH MODULE — Monitoring Dashboard & Alarms
# Provides operational visibility into IAM activity, EC2 metrics, and alerts
# ==============================================================================

# ------------------------------------------------------------------------------
# CLOUDWATCH DASHBOARD — Central monitoring pane
# Displays API activity, EC2 metrics, and CloudTrail event summaries
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      # --- Row 1: Header ---
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# 🔐 IAM User Management System — Monitoring Dashboard\n**Region:** ${var.aws_region} | **Account:** ${var.account_id} | **Updated:** Auto-refresh"
        }
      },

      # --- Row 2: EC2 Metrics ---
      {
        type   = "text"
        x      = 0
        y      = 1
        width  = 24
        height = 1
        properties = {
          markdown = "## 📊 EC2 Instance Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🖥️ CPU Utilization (%)"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.ec2_instance_id],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.ec2_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🌐 Network I/O (Bytes)"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", var.ec2_instance_id],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", var.ec2_instance_id],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", var.ec2_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "⚠️ Status Checks"
          period  = 300
          stat    = "Maximum"
        }
      },

      # --- Row 3: CloudTrail & API Activity ---
      {
        type   = "text"
        x      = 0
        y      = 8
        width  = 24
        height = 1
        properties = {
          markdown = "## 🔍 CloudTrail — API Activity & IAM Events"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          query   = <<-QUERY
            fields @timestamp, eventName, userIdentity.arn, sourceIPAddress, errorCode
            | filter eventSource like /iam/
            | sort @timestamp desc
            | limit 50
          QUERY
          region  = var.aws_region
          stacked = false
          view    = "table"
          title   = "🔑 Recent IAM API Calls"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          query   = <<-QUERY
            fields @timestamp, eventName, userIdentity.arn, sourceIPAddress
            | filter errorCode like /Unauthorized|AccessDenied|Forbidden/
            | sort @timestamp desc
            | limit 50
          QUERY
          region  = var.aws_region
          stacked = false
          view    = "table"
          title   = "🚨 Unauthorized Access Attempts"
        }
      },

      # --- Row 4: Console Sign-In Activity ---
      {
        type   = "log"
        x      = 0
        y      = 15
        width  = 12
        height = 6
        properties = {
          query   = <<-QUERY
            fields @timestamp, eventName, userIdentity.userName, sourceIPAddress, responseElements.ConsoleLogin
            | filter eventName = "ConsoleLogin"
            | sort @timestamp desc
            | limit 30
          QUERY
          region  = var.aws_region
          stacked = false
          view    = "table"
          title   = "🔐 Console Sign-In Events"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 15
        width  = 12
        height = 6
        properties = {
          query   = <<-QUERY
            fields @timestamp, eventName, userIdentity.arn, requestParameters.roleName
            | filter eventName = "AssumeRole" or eventName = "SwitchRole"
            | sort @timestamp desc
            | limit 30
          QUERY
          region  = var.aws_region
          stacked = false
          view    = "table"
          title   = "🔄 Role Assumption Events"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# CLOUDWATCH METRIC ALARMS — Proactive alerting
# Detects suspicious activity and operational issues
# ------------------------------------------------------------------------------

# Alarm: Unauthorized API calls detected
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-unauthorized-api-calls"
  alarm_description   = "Triggers when unauthorized API calls are detected in CloudTrail"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Purpose = "Security alert — unauthorized API calls"
  })
}

# Alarm: Root account usage detected (critical security event)
resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-root-account-usage"
  alarm_description   = "CRITICAL: Root account usage detected!"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Purpose = "Security alert — root account usage"
    Severity = "CRITICAL"
  })
}

# Alarm: IAM policy changes (security-relevant event)
resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-iam-policy-changes"
  alarm_description   = "IAM policy changes detected — review for unauthorized modifications"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyChanges"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Purpose = "Security alert — IAM policy modifications"
  })
}

# Alarm: EC2 instance CPU too high (operational)
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-ec2-high-cpu"
  alarm_description   = "EC2 instance CPU utilization exceeds 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = var.ec2_instance_id
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Purpose = "Operational alert — high CPU"
  })
}

# ------------------------------------------------------------------------------
# CLOUDWATCH METRIC FILTERS — Extract metrics from CloudTrail logs
# These filters create the custom metrics referenced by the alarms above
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  count = var.enable_alarms && var.cloudtrail_log_group_name != "" ? 1 : 0

  name           = "UnauthorizedAPICalls"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name          = "UnauthorizedAPICalls"
    namespace     = "CloudTrailMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  count = var.enable_alarms && var.cloudtrail_log_group_name != "" ? 1 : 0

  name           = "RootAccountUsage"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name          = "RootAccountUsage"
    namespace     = "CloudTrailMetrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  count = var.enable_alarms && var.cloudtrail_log_group_name != "" ? 1 : 0

  name           = "IAMPolicyChanges"
  log_group_name = var.cloudtrail_log_group_name
  pattern        = "{ ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"AttachRolePolicy\") || ($.eventName = \"DetachRolePolicy\") || ($.eventName = \"AttachUserPolicy\") || ($.eventName = \"DetachUserPolicy\") || ($.eventName = \"AttachGroupPolicy\") || ($.eventName = \"DetachGroupPolicy\") || ($.eventName = \"PutGroupPolicy\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"PutUserPolicy\") || ($.eventName = \"DeleteGroupPolicy\") || ($.eventName = \"DeleteRolePolicy\") || ($.eventName = \"DeleteUserPolicy\") }"

  metric_transformation {
    name          = "IAMPolicyChanges"
    namespace     = "CloudTrailMetrics"
    value         = "1"
    default_value = "0"
  }
}
