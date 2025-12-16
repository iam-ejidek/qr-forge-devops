output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.qr_forge.id
}

output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_eip.qr_forge.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i qr-forge.pem ubuntu@${aws_eip.qr_forge.public_ip}"
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_eip.qr_forge.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "s3_bucket_name" {
  description = "S3 Bucket for backups"
  value       = aws_s3_bucket.qr_forge_backups.id
}
