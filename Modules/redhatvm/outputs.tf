# ============================================================================
# Module: Red Hat VM (App Servers) - Outputs
# ============================================================================

output "redhatvm_ids" {
  description = "List of Red Hat VM IDs"
  value       = vsphere_virtual_machine.redhatvm[*].id
}

output "redhatvm_names" {
  description = "List of Red Hat VM names"
  value       = vsphere_virtual_machine.redhatvm[*].name
}

output "redhatvm_ip_addresses" {
  description = "List of Red Hat VM default IP addresses"
  value       = vsphere_virtual_machine.redhatvm[*].default_ip_address
}
