
variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Zone:Edit and Zone:DNS:Edit permissions"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Cloudflare Account ID where the zone will be created"
  type        = string
}

variable "zone_name" {
  description = "The domain name of the zone (e.g., example.com)"
  type        = string
}

variable "type" {
  description = "Zone type: 'full', 'partial', or 'secondary' (partial = CNAME setup)"
  type        = string
  default     = "full"
}
