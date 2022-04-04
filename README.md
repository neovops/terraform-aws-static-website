[![Neovops](https://neovops.io/images/logos/neovops.svg)](https://neovops.io)

# Terraform AWS static website module

Terraform module to provision a S3 Bucket and CloudFront distribution to
serve a static website.

This module creates:
 * a S3 bucket
 * a CloudFront distribution
 * an ACM certificate
 * a route53 record for the website

## Terraform registry

This module is available on
[terraform registry](https://registry.terraform.io/modules/neovops/static-website/aws/latest).

## Requirements

The Route53 zone must already exists.

## Providers

This module needs 3 providers:
 * aws - default provider for resources
 * aws.route53 - Where the route53 zone already exists
 * aws.us-east-1 same account as `aws`, for acm certificate

 This handle the use case where multiple aws accounts are used but it can be
 the same provider.

## Examples

### Simple

```hcl

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_route53_zone" "my_website_com" {
  name = "my-website.com"
}

module "static-website" {
  source = "neovops/static-website/aws"

  website_host = "example.my-website.com"
  dns_zone     = aws_route53_zone.my_website_com.name

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
```

### SPA Application

```hcl
module "static-website" {
  source = "neovops/static-website/aws"

  website_host = "example.my-website.com"
  dns_zone     = "my-website.com"
  redirect_404 = true

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
```

### Basic Authentication

```hcl
module "static-website" {
  source = "neovops/static-website/aws"

  website_host = "example.my-website.com"
  dns_zone     = "my-website.com"
  redirect_404 = true

  enable_basic_auth = true

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
```

It creates a lambda function that add basic authentication. The
username / password is stored in AWS Secret Manager in the `us-east-1`
region. The name of this secret is `"basic-auth/${var.website_host}"`. The
initial password is generated randomly but can be changed directly in AWS
Secret Manager.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.2 |
| <a name="provider_aws.route53"></a> [aws.route53](#provider\_aws.route53) | ~> 4.2 |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | ~> 4.2 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.oai](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_iam_role.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.website](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_policy.website](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_secretsmanager_secret.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.initial_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [archive_file.basic_auth](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_basic_auth_initial_username"></a> [basic\_auth\_initial\_username](#input\_basic\_auth\_initial\_username) | Initial username for basic authentication | `string` | `"admin"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Default object for root URL | `string` | `"index.html"` | no |
| <a name="input_dns_zone"></a> [dns\_zone](#input\_dns\_zone) | DNS Zone | `string` | n/a | yes |
| <a name="input_enable_basic_auth"></a> [enable\_basic\_auth](#input\_enable\_basic\_auth) | Enable basic authentication | `bool` | `false` | no |
| <a name="input_redirect_404"></a> [redirect\_404](#input\_redirect\_404) | Redirect all 404 requests to `redirect_404_object`. Usefull for SPA applications | `bool` | `false` | no |
| <a name="input_redirect_404_object"></a> [redirect\_404\_object](#input\_redirect\_404\_object) | Object for 404 redirect. Not used if `redirect_404` is false | `string` | `"/index.html"` | no |
| <a name="input_website_host"></a> [website\_host](#input\_website\_host) | Website Host | `string` | n/a | yes |

## Outputs

No outputs.
