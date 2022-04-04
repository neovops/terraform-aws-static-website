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

variable "redirect_404" {
  type        = bool
  description = "Redirect all 404 requests to `redirect_404_object`. Usefull for SPA applications"
  default     = false
}

variable "redirect_404_object" {
  type        = string
  description = "Object for 404 redirect. Not used if `redirect_404` is false"
  default     = "/index.html"
}

variable "enable_basic_auth" {
  type        = bool
  description = "Enable basic authentication"
  default     = false
}

variable "basic_auth_initial_username" {
  type        = string
  description = "Initial username for basic authentication"
  default     = "admin"
}
