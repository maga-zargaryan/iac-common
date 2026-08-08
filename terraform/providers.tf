terraform {
  required_version = "1.15.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.61.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.3"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy  = "terraform"
      Repository = "iac-common"
      Layer      = "network"
      Owner      = var.owner
    }
  }
}

provider "github" {
  token = var.github_token
}