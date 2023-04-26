/**
 * [![Neovops](https://neovops.io/images/logos/neovops.svg)](https://neovops.io)
 *
 * # Terraform AWS static website module
 *
 * Terraform module to provision a S3 Bucket and CloudFront distribution to
 * serve a static website.
 *
 * This module creates:
 *  * a S3 bucket
 *  * a CloudFront distribution
 *  * an ACM certificate
 *  * a route53 record for the website
 *
 *
 * ## Terraform registry
 *
 * This module is available on
 * [terraform registry](https://registry.terraform.io/modules/neovops/static-website/aws/latest).
 *
 *
 * ## Requirements
 *
 * The Route53 zone must already exists.
 *
 *
 * ## Providers
 *
 * This module needs 3 providers:
 *  * aws - default provider for resources
 *  * aws.route53 - Where the route53 zone already exists
 *  * aws.us-east-1 same account as `aws`, for acm certificate
 *
 *  This handle the use case where multiple aws accounts are used but it can be
 *  the same provider.
 *
 * ## Examples
 *
 * ### Simple
 *
 * ```hcl
 *
 * provider "aws" {
 *   region = "eu-west-1"
 * }
 *
 * provider "aws" {
 *   alias  = "us-east-1"
 *   region = "us-east-1"
 * }
 *
 * resource "aws_route53_zone" "my_website_com" {
 *   name = "my-website.com"
 * }
 *
 * module "static-website" {
 *   source = "neovops/static-website/aws"
 *
 *   website_host = "example.my-website.com"
 *   dns_zone     = aws_route53_zone.my_website_com.name
 *
 *   providers = {
 *     aws           = aws
 *     aws.route53   = aws
 *     aws.us-east-1 = aws.us-east-1
 *   }
 * }
 * ```
 *
 *
 * ### SPA Application
 *
 * ```hcl
 * module "static-website" {
 *   source = "neovops/static-website/aws"
 *
 *   website_host = "example.my-website.com"
 *   dns_zone     = "my-website.com"
 *   redirect_404 = true
 *
 *   providers = {
 *     aws           = aws
 *     aws.route53   = aws
 *     aws.us-east-1 = aws.us-east-1
 *   }
 * }
 * ```
 *
 * ### Basic Authentication
 *
 * ```hcl
 * module "static-website" {
 *   source = "neovops/static-website/aws"
 *
 *   website_host = "example.my-website.com"
 *   dns_zone     = "my-website.com"
 *   redirect_404 = true
 *
 *   enable_basic_auth = true
 *
 *   providers = {
 *     aws           = aws
 *     aws.route53   = aws
 *     aws.us-east-1 = aws.us-east-1
 *   }
 * }
 * ```
 *
 * It creates a lambda function that add basic authentication. The
 * username / password is stored in AWS Secret Manager in the `us-east-1`
 * region. The name of this secret is `"basic-auth/${var.website_host}"`. The
 * initial password is generated randomly but can be changed directly in AWS
 * Secret Manager.
 */

data "aws_route53_zone" "zone" {
  name = var.dns_zone

  provider = aws.route53
}


# ACM

resource "aws_acm_certificate" "cert" {
  domain_name       = var.website_host
  validation_method = "DNS"

  provider = aws.us-east-1
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = data.aws_route53_zone.zone.zone_id
  ttl     = 60

  provider = aws.route53
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  provider = aws.us-east-1
}


# S3

resource "aws_s3_bucket" "website" {
  bucket = var.website_host
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website,
  ]

}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.website.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_policy.json
}


# CloudFront

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI - ${var.website_host}"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = var.default_root_object

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.enable_basic_auth ? [1] : []
      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.basic_auth.0.qualified_arn
        include_body = false
      }
    }
  }

  aliases = [var.website_host]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  dynamic "custom_error_response" {
    for_each = var.redirect_404 ? [1] : []
    content {
      error_code         = 404
      response_code      = 200
      response_page_path = var.redirect_404_object

    }
  }

  depends_on = [
    aws_acm_certificate_validation.cert,
  ]
}


# DNS

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.website_host
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = true
  }

  provider = aws.route53
}
