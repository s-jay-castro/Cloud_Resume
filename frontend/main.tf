resource "aws_s3_bucket" "website_bucket" {
  bucket = var.frontend_bucket_name
  force_destroy = true

  tags = {
    Project = "Cloud Resume Challenge"
    Component = "Frontend"
  }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.website_bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
resource "aws_cloudfront_origin_access_control" "oac" {
  name = "resume-s3-oac"
  description = "Secures S3 access so only CloudFront can read files"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "website_cdn" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  aliases = [var.custom_domain_name, "www.${var.custom_domain_name}"]

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id = "S3-${aws_s3_bucket.website_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }
 
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

    restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Project = "Cloud Resume Challenge"
    Component = "Frontend"
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_acm_certificate" "cert" {
  provider = aws.va
  domain_name = var.custom_domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.custom_domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  provider        = aws.va
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = [
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.resource_record_name
  ]

}

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
