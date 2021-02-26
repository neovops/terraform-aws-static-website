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
 *  * a ACM certificate (in us-east-1 zone)
 *  * a route53 record for the website
 *
 *
 * ## Terraform registry
 *
 * This module is available on
 * [terraform registry](https://registry.terraform.io/modules/neovops/static-website/aws/latest).
 *
 *
 * ## Example
 *
 */

