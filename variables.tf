variable "website_host" {
  type        = string
  description = "Website Host"
}

variable "dns_zone" {
  type        = string
  description = "DNS Zone"
}

variable "default_root_object" {
  type        = string
  description = "Default object for root URL"
  default     = "index.html"
}
