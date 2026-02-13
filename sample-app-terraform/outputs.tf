# ============================================================================
# Terraform Outputs - Captured by Jenkins Pipeline
# ============================================================================
# These outputs are archived as tf-outputs-<env>.json by Stage 4 of the
# pipeline and included in the deployment report from Stage 6.
# ============================================================================

output "lb_ip" {
  description = "HAProxy load balancer IP address"
  value       = module.load_balancer.lb_ip
}

output "lb_name" {
  description = "HAProxy load balancer VM name"
  value       = module.load_balancer.lb_name
}

output "reverse_proxy_ips" {
  description = "Apache HTTPD reverse proxy IP addresses"
  value       = module.reverse_proxies.vm_ip_addresses
}

output "reverse_proxy_names" {
  description = "Apache HTTPD reverse proxy VM names"
  value       = module.reverse_proxies.vm_names
}

output "app_server_ips" {
  description = "Application server IP addresses"
  value       = module.app_servers.vm_ip_addresses
}

output "app_server_names" {
  description = "Application server VM names"
  value       = module.app_servers.vm_names
}

output "nfs_data_ip" {
  description = "NFS data server IP address"
  value       = module.nfs_data.nfs_ip
}

output "nfs_binaries_ip" {
  description = "NFS binaries server IP address"
  value       = module.nfs_binaries.nfs_ip
}

output "firewall_policy_id" {
  description = "NSX-T firewall security policy ID"
  value       = module.firewall.security_policy_id
}
