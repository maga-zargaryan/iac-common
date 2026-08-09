output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Tier 1 — public subnets, for internet-facing load balancers."
  value       = module.vpc.public_subnets
}

output "app_subnet_ids" {
  description = "Tier 2 — private app subnets, for compute."
  value       = module.vpc.private_subnets
}

output "data_subnet_ids" {
  description = "Tier 3 — isolated data subnets, for RDS and EFS."
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "RDS DB subnet group covering the data tier."
  value       = module.vpc.database_subnet_group_name
}

output "build_subnet_id" {
  description = "Ephemeral build subnet for EC2 Image Builder."
  value       = aws_subnet.build_1a.id
}

output "vpc_endpoint_security_group_id" {
  description = "Security group ID attached to the private endpoints."
  value       = aws_security_group.vpc_endpoints.id
}

output "route53_zone_id" {
  description = "Hosted zone ID for the domain."
  value       = aws_route53_zone.primary.zone_id
}

output "route53_name_servers" {
  description = "Name servers — must match the delegation at the registrar."
  value       = aws_route53_zone.primary.name_servers
}