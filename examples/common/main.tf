module "static-webiste" {
  source = "../../"

  website_host = "example.neovops.io"
  dns_zone     = "neovops.io"
}
