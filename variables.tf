variable "project_name" {
  description = "Project name identifier"
  type        = string
  default     = "nginxdemo"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "availability_zones" {
  description = "AZs to deploy resources in"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "domain_name" {
  description = "The FQDN to request a TLS certificate for (must exist in Route 53)"
  type        = string
}

variable "my_ip" {
  description = "Your IP for SSH access to Bastion (CIDR format)"
  type        = string
}

#variable "acm_certificate_arn" {
#  description = "ARN of the ACM certificate for ALB"
#  type        = string
#}

variable "ssh_key_name" {
  description = "The name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "enable_bastion" {
  description = "Set to true to create a Bastion host"
  type        = bool
  default     = false
}