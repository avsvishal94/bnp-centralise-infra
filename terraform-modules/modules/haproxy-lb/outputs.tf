# ============================================================================
# Terraform Module: HAProxy Load Balancer - Outputs
# ============================================================================

output "lb_id" {
  description = "Load balancer VM ID"
  value       = module.lb_vm.vm_ids[0]
}

output "lb_name" {
  description = "Load balancer VM name"
  value       = module.lb_vm.vm_names[0]
}

output "lb_ip" {
  description = "Load balancer IP address"
  value       = module.lb_vm.vm_ip_addresses[0]
}
