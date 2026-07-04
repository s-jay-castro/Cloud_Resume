# Needs to specify required providers, source and version
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Set provider region, default tags and aliases
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "Cloud Resume Challenge"
      Owner = "S. J. Castro"
    }
  }
}