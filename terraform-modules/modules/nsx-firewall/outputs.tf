# ============================================================================
# Terraform Module: NSX-T Firewall - Outputs
# ============================================================================

output "security_policy_id" {
  description = "NSX-T security policy ID"
  value       = nsxt_policy_security_policy.firewall.id
}

output "security_policy_path" {
  description = "NSX-T security policy path"
  value       = nsxt_policy_security_policy.firewall.path
}

output "app_server_group_path" {
  description = "NSX-T application server group path"
  value       = nsxt_policy_group.app_servers.path
}
