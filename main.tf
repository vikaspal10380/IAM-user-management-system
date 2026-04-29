# ==============================================================================
# ROOT MAIN.TF — IAM User Management System
# Orchestrates all modules to build a complete IAM RBAC infrastructure
#
# Architecture:
#   IAM Module    → Users, Groups, Policies, EC2 Role
#   S3 Module     → Encrypted audit log bucket
#   CloudTrail    → Multi-region API audit logging
#   EC2 Module    → Demo instance with IAM role (no static keys)
#   CloudWatch    → Monitoring dashboard & security alarms
#   SNS Module    → Alert notifications (bonus)
# ==============================================================================

# ==============================================================================
# MODULE 1: IAM — Users, Groups, Policies, and Roles
# This is the core of the RBAC system
# ==============================================================================

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  iam_users           = var.iam_users
  force_destroy_users = var.force_destroy_users
  common_tags         = var.common_tags
}

# ==============================================================================
# MODULE 2: S3 — Secure Audit Log Bucket
# Must be created BEFORE CloudTrail (CloudTrail writes logs here)
# ==============================================================================

module "s3" {
  source = "./modules/s3"

  bucket_name     = var.audit_bucket_name
  force_destroy   = var.s3_force_destroy
  aws_region      = var.aws_region
  cloudtrail_name = var.cloudtrail_name
  common_tags     = var.common_tags
}

# ==============================================================================
# MODULE 3: CLOUDTRAIL — Auditing & Compliance
# Depends on S3 bucket (log destination) being ready
# ==============================================================================

module "cloudtrail" {
  source = "./modules/cloudtrail"

  trail_name                  = var.cloudtrail_name
  s3_bucket_id                = module.s3.bucket_id
  s3_bucket_policy_dependency = module.s3.bucket_id # Ensures S3 policy exists first
  project_name                = var.project_name
  common_tags                 = var.common_tags

  depends_on = [module.s3]
}

# ==============================================================================
# MODULE 4: EC2 — Demo Instance with IAM Role
# Uses the instance profile created by the IAM module
# ==============================================================================

module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  ami_id                = var.ec2_ami_id != "" ? var.ec2_ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type         = var.ec2_instance_type
  subnet_id             = var.ec2_subnet_id != "" ? var.ec2_subnet_id : data.aws_subnets.default.ids[0]
  vpc_id                = var.ec2_vpc_id != "" ? var.ec2_vpc_id : data.aws_vpc.default.id
  instance_profile_name = module.iam.ec2_instance_profile_name
  key_pair_name         = var.ec2_key_pair_name
  common_tags           = var.common_tags

  depends_on = [module.iam]
}

# ==============================================================================
# MODULE 5: SNS — Security Alert Notifications (Bonus)
# Created conditionally based on enable_sns_alerts variable
# ==============================================================================

module "sns" {
  source = "./modules/sns"
  count  = var.enable_sns_alerts ? 1 : 0

  project_name = var.project_name
  alert_email  = var.alert_email
  common_tags  = var.common_tags
}

# ==============================================================================
# MODULE 6: CLOUDWATCH — Monitoring Dashboard & Alarms
# Depends on EC2 and CloudTrail for metrics/log sources
# ==============================================================================

module "cloudwatch" {
  source = "./modules/cloudwatch"

  dashboard_name            = var.cloudwatch_dashboard_name
  project_name              = var.project_name
  aws_region                = var.aws_region
  account_id                = data.aws_caller_identity.current.account_id
  ec2_instance_id           = module.ec2.instance_id
  cloudtrail_log_group_name = module.cloudtrail.cloudwatch_log_group_name
  enable_alarms             = true
  sns_topic_arn             = var.enable_sns_alerts ? module.sns[0].topic_arn : ""
  common_tags               = var.common_tags

  depends_on = [module.ec2, module.cloudtrail]
}
