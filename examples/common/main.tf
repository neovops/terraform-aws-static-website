module "static-website" {
  source = "../../"

  website_host = "example.neovops.io"
  dns_zone     = "neovops.io"

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
