# ==============================================================================
# S3 MODULE — Secure Audit Log Bucket
# Creates an encrypted, access-restricted S3 bucket for CloudTrail logs
# ==============================================================================

# ------------------------------------------------------------------------------
# S3 BUCKET — Core audit log storage
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "audit_logs" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Purpose = "CloudTrail audit log storage"
    Name    = var.bucket_name
  })
}

# ------------------------------------------------------------------------------
# VERSIONING — Enable versioning for audit log integrity
# Ensures logs cannot be silently overwritten or deleted
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# SERVER-SIDE ENCRYPTION — AES-256 (SSE-S3) by default
# All objects stored in this bucket are encrypted at rest
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# ------------------------------------------------------------------------------
# PUBLIC ACCESS BLOCK — Prevent any public access to audit logs
# Critical security measure: audit logs must never be publicly exposed
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# LIFECYCLE RULES — Manage log retention and cost optimization
# Transitions logs to cheaper storage classes, deletes after 365 days
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "audit-log-lifecycle"
    status = "Enabled"

    filter {}

    # Move to Infrequent Access after 30 days (cheaper storage)
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 90 days (archival storage)
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 365 days (configurable via variable)
    expiration {
      days = var.log_retention_days
    }
  }
}

# ------------------------------------------------------------------------------
# BUCKET POLICY — Allow CloudTrail to write logs
# CloudTrail requires explicit bucket policy permission to deliver log files
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_access" {
  bucket = aws_s3_bucket.audit_logs.id

  # Ensure public access block is applied before the policy
  depends_on = [aws_s3_bucket_public_access_block.audit_logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"
          }
        }
      },
      {
  Sid    = "DenyUnencryptedObjectUploads"
  Effect = "Deny"
  Principal = "*"
  Action   = "s3:PutObject"
  Resource = "${aws_s3_bucket.audit_logs.arn}/*"

  Condition = {
    StringNotEquals = {
      "s3:x-amz-server-side-encryption" = "aws:kms"
    }
    StringNotLike = {
      "aws:PrincipalServiceName" = "cloudtrail.amazonaws.com"
    }
  }
},
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_logs.arn,
          "${aws_s3_bucket.audit_logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
