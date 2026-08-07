import {
  to = aws_route53_zone.primary
  id = var.hosted_zone_id
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name

  lifecycle {
    prevent_destroy = true
  }
}