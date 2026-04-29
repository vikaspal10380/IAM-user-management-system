# ==============================================================================
# CLOUDTRAIL MODULE — Auditing & Compliance
# Enables multi-region API logging for security auditing
# ==============================================================================

# ------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP — Destination for CloudTrail log streaming
# Allows real-time monitoring and alerting on CloudTrail events
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.trail_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Purpose = "CloudTrail log streaming"
  })
}

# ------------------------------------------------------------------------------
# IAM ROLE FOR CLOUDTRAIL → CLOUDWATCH LOGS
# CloudTrail needs permission to write to CloudWatch Logs
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name               = "${var.project_name}-cloudtrail-cw-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json

  tags = merge(var.common_tags, {
    Purpose = "CloudTrail to CloudWatch Logs delivery"
  })
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.cloudtrail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name   = "${var.project_name}-cloudtrail-cw-policy"
  role   = aws_iam_role.cloudtrail_cloudwatch.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

# ------------------------------------------------------------------------------
# CLOUDTRAIL TRAIL — The core audit trail
# Multi-region, with log file validation enabled for tamper detection
# ------------------------------------------------------------------------------

resource "aws_cloudtrail" "main" {
  name = var.trail_name

  # S3 destination for log storage
  s3_bucket_name = var.s3_bucket_id

  # Enable for ALL regions (not just the deployment region)
  is_multi_region_trail = true

  # Global service events (IAM, STS, CloudFront)
  include_global_service_events = true

  # Log file validation (detect tampering)
  enable_log_file_validation = true

  # Stream to CloudWatch Logs for real-time monitoring
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  # Enable logging
  enable_logging = true

  # Log data events for S3 and Lambda (optional, increases cost)
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  }

  tags = merge(var.common_tags, {
    Purpose = "Security auditing and compliance"
    Name    = var.trail_name
  })

  # Ensure the bucket policy is in place before creating the trail
  depends_on = [var.s3_bucket_policy_dependency]
}
