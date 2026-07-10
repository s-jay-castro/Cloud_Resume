output "api_endpoint" {
  description = "Base URL for your resume visitor counter API"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}