# 🔐 IAM User Management System

A production-grade AWS IAM Role-Based Access Control (RBAC) system built with Terraform. This project implements secure multi-user access management with auditing, monitoring, billing restriction, and credential-free EC2 access.

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS Account                                  │
│                                                                     │
│  ┌──────────────────── IAM ────────────────────┐                   │
│  │                                              │                   │
│  │  Users           Groups          Policies    │                   │
│  │  ┌────────┐     ┌───────────┐   ┌─────────┐ │                   │
│  │  │ admin  │────▶│ AdminGroup│──▶│FullAcces│ │                   │
│  │  └────────┘     └───────────┘   └─────────┘ │                   │
│  │  ┌────────┐     ┌───────────┐   ┌─────────┐ │                   │
│  │  │  dev   │────▶│ DevGroup  │──▶│EC2+S3RO │ │                   │
│  │  └────────┘     └───────────┘   └─────────┘ │                   │
│  │  ┌────────┐     ┌───────────┐   ┌─────────┐ │                   │
│  │  │ tester │────▶│TesterGroup│──▶│ReadOnly │ │                   │
│  │  └────────┘     └───────────┘   └─────────┘ │                   │
│  │  ┌────────┐     ┌───────────┐   ┌─────────┐ │                   │
│  │  │billing │────▶│BillingGrp │──▶│Billing  │ │                   │
│  │  └────────┘     └───────────┘   └─────────┘ │                   │
│  │                                              │                   │
│  │  ┌───────────────────────────────────────┐   │                   │
│  │  │  EC2_Access_Role (Instance Profile)   │   │                   │
│  │  │  • AmazonS3ReadOnlyAccess             │   │                   │
│  │  │  • CloudWatchLogsFullAccess           │   │                   │
│  │  └───────────────┬───────────────────────┘   │                   │
│  └──────────────────┼───────────────────────────┘                   │
│                     │                                               │
│  ┌──────────────────▼───────────┐  ┌──────────────────────────┐    │
│  │  EC2 Instance                │  │  S3 Bucket (Encrypted)   │    │
│  │  • Amazon Linux 2023         │  │  • iam-audit-logs-bucket │    │
│  │  • IAM Role attached         │──│  • Block public access   │    │
│  │  • No access keys!           │  │  • Versioning enabled    │    │
│  │  • IMDSv2 enforced           │  │  • Lifecycle rules       │    │
│  └──────────────────────────────┘  └──────────────┬───────────┘    │
│                                                    │                │
│  ┌─────────────────────────────────────────────────┤               │
│  │  CloudTrail                                     │                │
│  │  • Multi-region enabled                         │                │
│  │  • Log validation enabled          Logs ────────┘                │
│  │  • Global service events                                        │
│  │  • S3 data events                                               │
│  └──────────────┬──────────────────────────────────┐               │
│                 │                                   │               │
│  ┌──────────────▼──────────┐  ┌────────────────────▼──────────┐   │
│  │  CloudWatch Logs        │  │  CloudWatch Dashboard          │   │
│  │  • Real-time log stream │  │  • EC2 metrics                 │   │
│  │  • Metric filters       │  │  • IAM API calls               │   │
│  └─────────────────────────┘  │  • Unauthorized access         │   │
│                               │  • Console sign-ins            │   │
│  ┌────────────────────────┐   └────────────────────────────────┘   │
│  │  SNS (Bonus)           │                                        │
│  │  • Security alerts     │                                        │
│  │  • Email notifications │                                        │
│  └────────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Project Structure

```
IAM user management system/
├── main.tf                        # Root orchestration — wires all modules
├── variables.tf                   # Root input variables
├── outputs.tf                     # Root outputs & deployment summary
├── versions.tf                    # Terraform & provider version constraints
├── data.tf                        # Data sources (AMI, VPC, account ID)
├── terraform.tfvars.example       # Example configuration (copy & customize)
├── .gitignore                     # Git ignore rules
├── README.md                      # This file
│
└── modules/
    ├── iam/                       # IAM Users, Groups, Policies, Roles
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── s3/                        # Encrypted S3 audit log bucket
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── cloudtrail/                # Multi-region API audit logging
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── ec2/                       # Demo EC2 instance with IAM role
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── cloudwatch/                # Monitoring dashboard & security alarms
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── sns/                       # Security alert notifications (bonus)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 🚀 Setup Instructions

### Prerequisites

1. **Terraform** >= 1.5.0 ([Install Guide](https://developer.hashicorp.com/terraform/install))
2. **AWS CLI** configured with credentials ([Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
3. **AWS Account** with administrative access (avoid using root account)

### Step 1: Configure AWS Credentials

```bash
# Option A: AWS CLI profile
aws configure --profile iam-mgmt
export AWS_PROFILE=iam-mgmt

# Option B: Environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Customize Configuration

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values (IMPORTANT: set a unique S3 bucket name)
# vim terraform.tfvars
```

**Key values to customize:**
- `audit_bucket_name` — Must be globally unique (append your account ID)
- `alert_email` — Your email for SNS security alerts
- `ec2_key_pair_name` — Existing key pair name for SSH access (optional)

### Step 3: Initialize & Deploy

```bash
# Initialize Terraform (downloads providers)
terraform init

# Review the execution plan
terraform plan -out=tfplan

# Apply the changes (creates all resources)
terraform apply tfplan
```

### Step 4: Verify Deployment

```bash
# View all outputs
terraform output

# View the deployment summary
terraform output deployment_summary
```

---

## 🧪 Testing & Validation

### Test 1: Verify IAM Users and Groups

```bash
# List all created users
aws iam list-users --path-prefix /users/

# List all groups
aws iam list-groups --path-prefix /groups/

# Verify user-group assignments
aws iam list-groups-for-user --user-name admin_user
aws iam list-groups-for-user --user-name dev_user
aws iam list-groups-for-user --user-name tester_user
aws iam list-groups-for-user --user-name billing_user
```

### Test 2: Verify Group Policies

```bash
# Check AdminGroup policies
aws iam list-attached-group-policies --group-name AdminGroup

# Check DevGroup policies (should show EC2 Full + S3 ReadOnly + Deny Billing)
aws iam list-attached-group-policies --group-name DevGroup

# Check TesterGroup policies (should show ReadOnly + Deny Billing)
aws iam list-attached-group-policies --group-name TesterGroup

# Check BillingGroup policies (should show custom billing policy)
aws iam list-attached-group-policies --group-name BillingGroup
```

### Test 3: Verify EC2 Instance Uses IAM Role (No Static Keys)

```bash
# Get the instance ID
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

# Verify IAM instance profile is attached
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn'

# If you have SSH access, connect and verify:
# ssh -i your-key.pem ec2-user@<public-ip>
# aws sts get-caller-identity   # Should show the EC2 role, not user credentials
# aws s3 ls                      # Should work (S3 ReadOnly via role)
# aws ec2 describe-instances    # Should FAIL (no EC2 permissions in role)
```

### Test 4: Verify CloudTrail is Active

```bash
# Check trail status
aws cloudtrail get-trail-status --name iam-audit-trail

# Verify trail configuration
aws cloudtrail describe-trails --trail-name-list iam-audit-trail

# Look up recent events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=iam.amazonaws.com \
  --max-results 5
```

### Test 5: Verify S3 Bucket Security

```bash
# Check public access block
aws s3api get-public-access-block \
  --bucket $(terraform output -raw audit_bucket_id)

# Check encryption
aws s3api get-bucket-encryption \
  --bucket $(terraform output -raw audit_bucket_id)

# Check versioning
aws s3api get-bucket-versioning \
  --bucket $(terraform output -raw audit_bucket_id)
```

### Test 6: Verify CloudWatch Dashboard

```bash
# List dashboards
aws cloudwatch list-dashboards

# Open dashboard in browser
echo "Dashboard URL: $(terraform output -raw cloudwatch_dashboard_url)"
```

### Test 7: Simulate Access Denied (RBAC Validation)

To fully test RBAC, create login profiles for users and attempt cross-boundary access:

```bash
# Create a login profile for dev_user (set a temporary password)
aws iam create-login-profile \
  --user-name dev_user \
  --password 'TempP@ssw0rd!2024' \
  --password-reset-required

# Sign into console as dev_user and verify:
# ✅ Can access EC2 console
# ✅ Can view S3 buckets (read-only)
# ❌ Cannot access Billing
# ❌ Cannot create IAM users

# Repeat for tester_user:
# ✅ Can view resources (read-only)
# ❌ Cannot create/modify any resources
# ❌ Cannot access Billing

# Repeat for billing_user:
# ✅ Can access Billing dashboard
# ❌ Cannot access EC2, S3, or other services
```

---

## 🔐 Security Features

| Feature | Implementation |
|---|---|
| **Least Privilege** | Each group has only the permissions needed for their role |
| **No Root Account** | Infrastructure deployed with IAM user, not root |
| **No Static Keys on EC2** | EC2 uses IAM instance profile (role-based access) |
| **IMDSv2 Enforced** | Prevents SSRF-based credential theft on EC2 |
| **S3 Encryption** | KMS server-side encryption on audit bucket |
| **S3 Public Access Blocked** | All four public access block settings enabled |
| **HTTPS Enforced** | S3 bucket policy denies non-HTTPS requests |
| **Password Policy** | 14+ chars, upper/lower/numbers/symbols, 90-day rotation |
| **CloudTrail Validation** | Log file integrity validation enabled |
| **Billing Isolation** | Explicit deny policy on non-billing groups |
| **SNS Alerts** | Real-time notifications for security events |
| **Resource Tagging** | All resources tagged for cost allocation and governance |

---

## 🧹 Cleanup

```bash
# Destroy all resources (WARNING: irreversible!)
terraform destroy

# Confirm by typing "yes" when prompted
```

---

## 📋 Notes

- **S3 Bucket Name**: Must be globally unique. Append your AWS account ID to avoid conflicts.
- **SNS Email**: After deployment, check your email and **confirm the SNS subscription** to receive alerts.
- **Billing Access**: IAM access to billing must be enabled in the **AWS Organization** or **Account Settings** for the BillingGroup policies to take effect.
- **EC2 Key Pair**: Optional. If not provided, the instance launches without SSH access (you can use SSM Session Manager instead).
- **Cost**: This project uses `t2.micro` (free-tier eligible). CloudTrail and CloudWatch may incur small charges.

---

## 📜 License

This project is provided for educational and reference purposes. Use at your own risk. Always review IAM policies before deploying to production environments.
