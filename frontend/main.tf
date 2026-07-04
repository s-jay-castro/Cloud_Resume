# ==============================================================================
# 1. STORAGE COMPONENT (S3 BUCKET)
# ==============================================================================
# Creates the storage container for your HTML, CSS, and JS files.
resource "aws_s3_bucket" "website_bucket" {
  bucket        = var.frontend_bucket_name
  force_destroy = true # Cleans out files automatically if you run 'terraform destroy'

  tags = {
    Project   = "Cloud Resume Challenge"
    Component = "Frontend"
  }
}

# Configures the S3 storage space to behave specifically like a web server.
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# ==============================================================================
# 2. SECURITY GUARD COMPONENT (ORIGIN ACCESS CONTROL)
# ==============================================================================
# Creates a lock mechanism. It proves to S3 that incoming requests are coming 
# from your verified CloudFront distribution, keeping the bucket private from the public.
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "resume-s3-oac"
  description                       = "Secures S3 access so only CloudFront can read files"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ==============================================================================
# 3. GLOBAL DELIVERY COMPONENT (CLOUDFRONT CDN)
# ==============================================================================
# Deploys your website onto edge servers worldwide for sub-second load times.
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # If you have an SSL certificate from AWS ACM, list your domain names here:
  # aliases = [var.custom_domain_name, "www.${var.custom_domain_name}"]

  # Connects the CDN directly to your S3 storage block up above
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # Caching and protocol configurations
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
    viewer_protocol_policy = "redirect-to-https" # Automatically upgrades HTTP requests

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Required geo-restriction block (leaving it open globally)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Uses the standard recommended, cost-friendly SSL certificate configuration
  # If using a custom domain, replace this sub-block with your ACM certificate reference
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project   = "Cloud Resume Challenge"
    Component = "Frontend"
  }
}

# ==============================================================================
# 4. S3 BUCKET POLICY LAYER
# ==============================================================================
# This is the permission sheet applied to S3. It explicitly states: 
# "Allow the specific CloudFront distribution above to run s3:GetObject on my files."
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
        Action   = "s3:GetObject"
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

# ==============================================================================
# 5. OUTPUTS (YOUR EXTERNAL DNS BLUEPRINTS)
# ==============================================================================
# Once you run 'terraform apply', these blocks print the exact strings you 
# need to copy into your external domain registrar (Namecheap, GoDaddy, etc.)
output "cloudfront_domain_name" {
  description = "Point your external custom domain CNAME record to this address"
  value       = aws_cloudfront_distribution.website_cdn.domain_name
}
