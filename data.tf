# ==============================================================================
# DATA SOURCES — Look up dynamic values from AWS
# ==============================================================================

# Current AWS account ID and region (used for ARN construction & policies)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Latest Amazon Linux 2023 AMI (used when no custom AMI is specified)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Default VPC (used when no custom VPC is specified)
data "aws_vpc" "default" {
  default = true
}

# Default subnets (used when no custom subnet is specified)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
