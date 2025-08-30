output "application_private_ip" {
  description = "Private IP address of the application server"
  value       = aws_instance.application.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private_subnet.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = aws_nat_gateway.my_nat_gateway.id
}

output "BastionHost" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "applicationHost" {
  description = "Private IP address of the application host"
  value       = aws_instance.application.private_ip
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.auth_key.key_name
}

output "public_sg_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public_sg.id
}

output "private_sg_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.tfstatebucket.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tf_state_table.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.log_group.name
}

output "ssh_bastion_command" {
  description = "Command to SSH into bastion host"
  value       = "ssh -i ~/.ssh/auth.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "ssh_application_command" {
  description = "Command to SSH into application server via bastion"
  value       = "ssh -i ~/.ssh/auth.pem -o ProxyCommand=\"ssh -W %h:%p -q ubuntu@${aws_instance.bastion.public_ip} -i ~/.ssh/auth.pem\" ubuntu@${aws_instance.application.private_ip}"
}

output "tls_private_key" {
  description = "Private SSH key content"
  value       = tls_private_key.auth_key.private_key_pem
  sensitive   = true
}