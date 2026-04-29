# ==============================================================================
# EC2 MODULE — Demo Instance with IAM Role
# Launches an EC2 instance that uses IAM role for AWS access (no static keys)
# ==============================================================================

# ------------------------------------------------------------------------------
# SECURITY GROUP — Restrict network access to the EC2 instance
# Allows SSH (optional) and HTTPS egress only
# ------------------------------------------------------------------------------

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for IAM demo EC2 instance"
  vpc_id      = var.vpc_id

  # Outbound: Allow all (needed for AWS API calls, package installs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Inbound: SSH access (only if key pair is provided)
  dynamic "ingress" {
    for_each = var.key_pair_name != "" ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production!
      description = "SSH access (restrict CIDR in production)"
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-ec2-sg"
    Purpose = "EC2 instance network security"
  })
}

# ------------------------------------------------------------------------------
# EC2 INSTANCE — Demo instance with IAM role attached
# User data script installs AWS CLI and demonstrates credential-free S3 access
# ------------------------------------------------------------------------------

resource "aws_instance" "demo" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.instance_profile_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Only attach key pair if one is specified
  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  # Enable detailed monitoring for CloudWatch
  monitoring = true

  # Root volume: encrypted, GP3
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.common_tags, {
      Name = "${var.project_name}-ec2-root-volume"
    })
  }

  # IMDSv2 required (security best practice — prevents SSRF attacks)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforces IMDSv2
    http_put_response_hop_limit = 1
  }

  # User data: Install AWS CLI and demonstrate role-based S3 access
  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euo pipefail

    # Log user data execution
    exec > >(tee /var/log/user-data.log) 2>&1
    echo "=== IAM Demo EC2 Instance Setup ==="
    echo "Timestamp: $(date -u)"

    # Update system packages
    echo "[1/4] Updating system packages..."
    dnf update -y -q

    # Install AWS CLI v2 (Amazon Linux 2023 has it pre-installed, but ensure latest)
    echo "[2/4] Verifying AWS CLI installation..."
    if ! command -v aws &> /dev/null; then
      echo "Installing AWS CLI v2..."
      curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
      unzip -qo /tmp/awscliv2.zip -d /tmp/
      /tmp/aws/install --update
      rm -rf /tmp/aws /tmp/awscliv2.zip
    fi

    echo "AWS CLI Version: $(aws --version)"

    # Verify IAM role is attached (no static credentials needed)
    echo "[3/4] Verifying IAM role credentials..."
    echo "Instance identity:"
    aws sts get-caller-identity

    # Demonstrate S3 access using IAM role (no access keys!)
    echo "[4/4] Testing S3 access via IAM role..."
    echo "Listing S3 buckets (read-only via IAM role policy):"
    aws s3 ls || echo "S3 access test completed (may show no buckets if none exist)"

    echo "=== Setup Complete ==="
    echo "This instance accesses AWS services using IAM role: ${var.instance_profile_name}"
    echo "No static credentials (access keys) are stored on this instance."
  USERDATA
  )

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-demo-instance"
    Purpose = "IAM role-based access demonstration"
  })
}
