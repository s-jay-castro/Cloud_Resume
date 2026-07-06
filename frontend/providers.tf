# Needs to specify required providers, source and version
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    spaceship = {
      source = "namecheap/spaceship"
      version = ">= 0.4.0"
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

provider "aws" {
  alias = "va"
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "Cloud Resume Challenge"
      Owner = "S. J. Castro"
    }
  }
}

provider "spaceship" {
  api_key = var.spaceship_api_key
  api_secret = var.spaceship_api_secret
}