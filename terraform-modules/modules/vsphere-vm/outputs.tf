# ============================================================================
# Terraform Module: vSphere VM - Outputs
# ============================================================================

output "vm_ids" {
  description = "List of VM IDs"
  value       = vsphere_virtual_machine.vm[*].id
}

output "vm_names" {
  description = "List of VM names"
  value       = vsphere_virtual_machine.vm[*].name
}

output "vm_ip_addresses" {
  description = "List of default IP addresses"
  value       = vsphere_virtual_machine.vm[*].default_ip_address
}
