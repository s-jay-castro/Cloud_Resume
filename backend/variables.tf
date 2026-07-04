variable "aws_region" {
  type = string
  description = "Default AWS Region for this project with lowest latency"
  default = "ap-southeast-2"
}

variable "dynamodb_table_name" {
  type = string
  description = "Table name for the visitor counter data"
  default = "webcounter"
}

variable "lambda_webcounter_update" {
  type = string
  description = "Lambda function to update the webcounter"
  default = "update_webcounter"
}