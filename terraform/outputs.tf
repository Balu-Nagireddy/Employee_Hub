# -----------------------------------------------------------------------
# EC2
# -----------------------------------------------------------------------
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app.public_dns
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "ssh_command" {
  description = "SSH or SSM command to connect to the EC2 instance"
  value       = var.key_pair_name != null ? "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.app.public_ip}" : "aws ssm start-session --target ${aws_instance.app.id}"
}

# -----------------------------------------------------------------------
# Service URLs
# -----------------------------------------------------------------------
output "frontend_url" {
  description = "Frontend application URL — React SPA served via nginx on port 80"
  value       = "http://${aws_instance.app.public_ip}"
}

output "gateway_url" {
  description = "KrakenD API Gateway URL — all API requests go through this (port 8080)"
  value       = "http://${aws_instance.app.public_ip}:8080"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${aws_instance.app.public_ip}:3001"
}

output "prometheus_url" {
  description = "Prometheus metrics URL"
  value       = "http://${aws_instance.app.public_ip}:9090"
}

# -----------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------
output "db_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "db_host" {
  description = "RDS PostgreSQL host"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "RDS PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

# -----------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# -----------------------------------------------------------------------
# Terraform State Backend
# -----------------------------------------------------------------------
output "s3_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Terraform state locking DynamoDB table name"
  value       = aws_dynamodb_table.terraform_lock.name
}
