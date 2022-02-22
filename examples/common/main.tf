module "static-website" {
  source = "../../"

  website_host = "example.neovops.io"
  dns_zone     = "neovops.io"
}
