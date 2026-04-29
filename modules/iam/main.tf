# ==============================================================================
# IAM MODULE — Users, Groups, Policies, and Roles
# Implements RBAC with least-privilege access controls
# ==============================================================================

# ------------------------------------------------------------------------------
# IAM GROUPS — Logical groupings for role-based access control
# Each group gets specific managed/custom policies attached
# ------------------------------------------------------------------------------

resource "aws_iam_group" "admin" {
  name = "AdminGroup"
  path = "/groups/"
}

resource "aws_iam_group" "dev" {
  name = "DevGroup"
  path = "/groups/"
}

resource "aws_iam_group" "tester" {
  name = "TesterGroup"
  path = "/groups/"
}

resource "aws_iam_group" "billing" {
  name = "BillingGroup"
  path = "/groups/"
}

# ------------------------------------------------------------------------------
# GROUP POLICY ATTACHMENTS — AWS Managed Policies
# Using managed policies where possible per best practices
# ------------------------------------------------------------------------------

# AdminGroup: Full administrative access
resource "aws_iam_group_policy_attachment" "admin_full_access" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# DevGroup: Full EC2 access for development and deployment
resource "aws_iam_group_policy_attachment" "dev_ec2_full" {
  group      = aws_iam_group.dev.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# DevGroup: Read-only S3 access for pulling artifacts/configs
resource "aws_iam_group_policy_attachment" "dev_s3_readonly" {
  group      = aws_iam_group.dev.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# TesterGroup: Read-only access across all services for testing/validation
resource "aws_iam_group_policy_attachment" "tester_readonly" {
  group      = aws_iam_group.tester.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# BillingGroup: Custom billing policy (attached below)

# ------------------------------------------------------------------------------
# CUSTOM BILLING POLICY — Restricts access to billing console only
# This follows least-privilege: billing users cannot access any other service
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "billing_access" {
  name        = "${var.project_name}-billing-access-policy"
  path        = "/custom/"
  description = "Custom policy granting access to AWS Billing console only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBillingPortalAccess"
        Effect = "Allow"
        Action = [
          # Billing portal permissions
          "aws-portal:ViewBilling",
          "aws-portal:ViewUsage",
          "aws-portal:ViewPaymentMethods",
          "aws-portal:ViewAccount",
          # Cost Explorer & Budgets (read-only)
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "ce:DescribeCostCategoryDefinition",
          "budgets:ViewBudget",
          # Cost & Usage Reports
          "cur:DescribeReportDefinitions"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Purpose = "Billing access restriction"
  })
}

resource "aws_iam_group_policy_attachment" "billing_custom" {
  group      = aws_iam_group.billing.name
  policy_arn = aws_iam_policy.billing_access.arn
}

# ------------------------------------------------------------------------------
# DENY BILLING POLICY — Explicitly deny billing for non-billing groups
# Applied to Dev and Tester groups to prevent any billing access
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "deny_billing" {
  name        = "${var.project_name}-deny-billing-policy"
  path        = "/custom/"
  description = "Explicitly denies access to billing for non-billing users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyBillingAccess"
        Effect = "Deny"
        Action = [
          "aws-portal:*",
          "ce:*",
          "budgets:*",
          "cur:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Purpose = "Deny billing for non-billing users"
  })
}

resource "aws_iam_group_policy_attachment" "dev_deny_billing" {
  group      = aws_iam_group.dev.name
  policy_arn = aws_iam_policy.deny_billing.arn
}

resource "aws_iam_group_policy_attachment" "tester_deny_billing" {
  group      = aws_iam_group.tester.name
  policy_arn = aws_iam_policy.deny_billing.arn
}

# ------------------------------------------------------------------------------
# IAM USERS — Individual user accounts with console access
# Users are created without access keys (following best practice of using roles)
# ------------------------------------------------------------------------------

resource "aws_iam_user" "users" {
  for_each = var.iam_users

  name          = each.key
  path          = "/users/"
  force_destroy = var.force_destroy_users

  tags = merge(var.common_tags, each.value.tags, {
    Username = each.key
    Group    = each.value.group
  })
}

# Map of group names to group resource names for dynamic membership assignment
locals {
  group_name_map = {
    "AdminGroup"   = aws_iam_group.admin.name
    "DevGroup"     = aws_iam_group.dev.name
    "TesterGroup"  = aws_iam_group.tester.name
    "BillingGroup" = aws_iam_group.billing.name
  }
}

# Assign each user to their designated group
resource "aws_iam_user_group_membership" "user_groups" {
  for_each = var.iam_users

  user   = aws_iam_user.users[each.key].name
  groups = [local.group_name_map[each.value.group]]
}

# ------------------------------------------------------------------------------
# IAM ROLE FOR EC2 — Allows EC2 instances to access AWS services
# without embedding credentials (security best practice)
# ------------------------------------------------------------------------------

# Trust policy: Only EC2 service can assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_access_role" {
  name               = "EC2_Access_Role"
  path               = "/roles/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  description        = "IAM role for EC2 instances to access S3 (read) and CloudWatch Logs"

  tags = merge(var.common_tags, {
    Purpose = "EC2 instance role for S3 and CloudWatch access"
  })
}

# Attach S3 ReadOnly access to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_s3_readonly" {
  role       = aws_iam_role.ec2_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach CloudWatch Logs Full access to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logs" {
  role       = aws_iam_role.ec2_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Instance profile: The "wrapper" that allows attaching the role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_access_role.name

  tags = var.common_tags
}

# ------------------------------------------------------------------------------
# PASSWORD POLICY — Enforce secure password requirements across the account
# ------------------------------------------------------------------------------

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
  hard_expiry                    = false
}
