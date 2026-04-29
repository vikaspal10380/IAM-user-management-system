# ==============================================================================
# S3 MODULE — Outputs
# ==============================================================================

output "bucket_id" {
  description = "ID of the audit log S3 bucket"
  value       = aws_s3_bucket.audit_logs.id
}

output "bucket_arn" {
  description = "ARN of the audit log S3 bucket"
  value       = aws_s3_bucket.audit_logs.arn
}

output "bucket_domain_name" {
  description = "Domain name of the audit log S3 bucket"
  value       = aws_s3_bucket.audit_logs.bucket_domain_name
}
