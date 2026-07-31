output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jump_server.id
}

output "public_ip" {
  description = "Public IP of the jump server"
  value       = aws_instance.jump_server.public_ip
}

output "public_dns" {
  description = "Public DNS of the jump server"
  value       = aws_instance.jump_server.public_dns
}

output "security_group_id" {
  description = "Security group ID of the jump server"
  value       = aws_security_group.jump_server.id
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the jump server"
  value       = aws_iam_role.jump_server.arn
}

output "iam_role_name" {
  description = "IAM role name attached to the jump server"
  value       = aws_iam_role.jump_server.name
}

output "console_connect_url" {
  description = "AWS Console URL to connect to the jump server"
  value       = "https://console.aws.amazon.com/ec2/v2/home?#ConnectToInstance:instanceId=${aws_instance.jump_server.id}"
}
