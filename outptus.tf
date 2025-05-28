output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.app_alb.dns_name
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 app instances"
  value       = [for instance in aws_instance.app : instance.private_ip]
}

output "instance_azs" {
  description = "Availability Zones of EC2 app instances"
  value       = [for instance in aws_instance.app : instance.availability_zone]
}

output "bastion_public_ip" {
  description = "Public IP of Bastion host (if enabled)"
  value       = try(aws_instance.bastion.public_ip, null)
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate used for HTTPS"
  value       = aws_acm_certificate.this.arn
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.this.zone_id
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (needed for Route53 alias)"
  value       = aws_lb.app_alb.zone_id
}

output "app_security_group_id" {
  description = "Security group ID attached to EC2 app instances"
  value       = aws_security_group.app_sg.id
}

output "bastion-ssh-pubkey_secret_arn" {
  description = "ARN of the Secrets Manager secret storing Bastion SSH public key"
  value       = aws_secretsmanager_secret.bastion-ssh-pubkey.arn
}

output "bastion_instance_id" {
  description = "EC2 Instance ID of the Bastion host"
  value       = aws_instance.bastion.id
}