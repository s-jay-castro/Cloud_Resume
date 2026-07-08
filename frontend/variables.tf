variable "aws_region" {
  type = string
  description = "Default AWS Region for this project with lowest latency"
  default = "ap-southeast-2"
}

variable "frontend_bucket_name" {
  type = string
  description = "Unique S3 Bucket Name"
  default = "test-doughsmiles-01-apse02"
}

variable "custom_domain_name" {
  type = string
  description = "Fully qualified domain name being used for the cloud resume project"
  default = "doughsmiles.com"
}
