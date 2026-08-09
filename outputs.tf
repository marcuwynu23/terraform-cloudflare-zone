
output "zone_id" {
  description = "The Cloudflare Zone ID"
  value       = cloudflare_zone.this.id
}

output "zone_name" {
  description = "The zone name (domain)"
  value       = cloudflare_zone.this.name
}

output "name_servers" {
  description = "Cloudflare nameservers assigned to the zone (use these at your registrar)"
  value       = cloudflare_zone.this.name_servers
}

output "status" {
  description = "The zone status (e.g., active, pending)"
  value       = cloudflare_zone.this.status
}

output "account_id" {
  description = "The Cloudflare Account ID the zone belongs to"
  value       = cloudflare_zone.this.account.id
}
