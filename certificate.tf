# Request public ACM certificate
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "${var.project_name}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Use existing hosted zone
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# DNS validation record
locals {
  cert_validation = one(aws_acm_certificate.this.domain_validation_options) # one() is a function that returns the first element of the list = for a single domain
}

resource "aws_route53_record" "validation" {
  name    = local.cert_validation.resource_record_name
  type    = local.cert_validation.resource_record_type
  zone_id = data.aws_route53_zone.selected.zone_id
  records = [local.cert_validation.resource_record_value]
  ttl     = 60

  depends_on = [aws_acm_certificate.this]
}

# Trigger ACM to complete DNS validation
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.validation.fqdn]

  depends_on = [aws_route53_record.validation]
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID used for certificate validation"
  value       = data.aws_route53_zone.selected.zone_id
}