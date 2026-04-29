# ==============================================================================
# EC2 MODULE — Outputs
# ==============================================================================

output "instance_id" {
  description = "ID of the demo EC2 instance"
  value       = aws_instance.demo.id
}

output "instance_arn" {
  description = "ARN of the demo EC2 instance"
  value       = aws_instance.demo.arn
}

output "private_ip" {
  description = "Private IP address of the demo EC2 instance"
  value       = aws_instance.demo.private_ip
}

output "public_ip" {
  description = "Public IP address of the demo EC2 instance (if assigned)"
  value       = aws_instance.demo.public_ip
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}
