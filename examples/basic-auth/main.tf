module "static-website" {
  source = "../../"

  website_host = "example2.neovops.io"
  dns_zone     = "neovops.io"

  enable_basic_auth = true

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
