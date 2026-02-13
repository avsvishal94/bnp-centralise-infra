# ============================================================================
# Module: Apache Reverse Proxy - Outputs
# ============================================================================

output "apache_vm_ids" {
  description = "List of Apache VM IDs"
  value       = vsphere_virtual_machine.apache[*].id
}

output "apache_vm_names" {
  description = "List of Apache VM names"
  value       = vsphere_virtual_machine.apache[*].name
}

output "apache_ip_addresses" {
  description = "List of Apache VM default IP addresses"
  value       = vsphere_virtual_machine.apache[*].default_ip_address
}
