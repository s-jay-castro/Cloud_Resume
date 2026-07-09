output "acm_validation_records" {
  description = "Add these CNAMEs manually in your Spaceship DNS dashboard to validate the certificate."
  value = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      type = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}
output "cloudfront_domain_name" {
  description = "Point your external custom domain CNAME record to this address"
  value = aws_cloudfront_distribution.website_cdn.domain_name
}
