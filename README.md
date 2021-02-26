[![Neovops](https://neovops.io/images/logos/neovops.svg)](https://neovops.io)

# Terraform AWS static website module

Terraform module to provision a S3 Bucket and CloudFront distribution to  
serve a static website.

This module creates:
 * a S3 bucket
 * a CloudFront distribution
 * an ACM certificate (in us-east-1 zone)
 * a route53 record for the website

## Terraform registry

This module is available on
[terraform registry](https://registry.terraform.io/modules/neovops/static-website/aws/latest).

## Requirements

The Route53 zone must already exists.

## Examples

### Simple

```hcl
resource "aws_route53_zone" "my_website_com" {
  name = "my-website.com"
}

module "static-webiste" {
  source = "neovops/static-website/aws"

  website_host = "example.my-website.com"
  dns_zone     = aws_route53_zone.my_website_com.name
}
```

### SPA Application

```hcl
module "static-webiste" {
  source = "neovops/static-website/aws"

  website_host = "example.my-website.com"
  dns_zone     = "my-website.com"
  redirect_404 = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| aws | >= 3.30.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.30.0 |
| aws.us-east-1 | >= 3.30.0 |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) |
| [aws_acm_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) |
| [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) |
| [aws_cloudfront_origin_access_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) |
| [aws_route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) |
| [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) |
| [aws_s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| default\_root\_object | Default object for root URL | `string` | `"index.html"` | no |
| dns\_zone | DNS Zone | `string` | n/a | yes |
| redirect\_404 | Redirect all 404 requests to `redirect_404_object`. Usefull for SPA applications | `bool` | `false` | no |
| redirect\_404\_object | Object for 404 redirect. Not used if `redirect_404` is false | `string` | `"index.html"` | no |
| website\_host | Website Host | `string` | n/a | yes |

## Outputs

No output.
