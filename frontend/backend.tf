terraform {
  backend "s3" {
    bucket = "doughsmiles-s3-terraform"
    key = "frontend/terraform.tfstate"
    region = "ap-southeast-2"
    encrypt = true
  }
}