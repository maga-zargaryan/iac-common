variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-west-1"
}

variable "owner" {
  description = "Team or individual accountable for this infrastructure."
  type        = string
  default     = "platform"
}

variable "domain_name" {
  description = "Root domain of the existing Route 53 hosted zone."
  type        = string
  default     = "margarita.c-loud.am"
}

variable "hosted_zone_id" {
  description = "ID of the existing hosted zone to import."
  type        = string
  default     = "Z08564813V58TNSVCWMOQ"
}

variable "github_repository" {
  description = "Repository holding this configuration."
  type        = string
  default     = "iac-common"
}

variable "github_token" {
  description = "Fine-grained PAT for the github provider. Supplied via TF_VAR_github_token."
  type        = string
  sensitive   = true
}