# ============================================================================
# Terraform Module: NFS Server - Outputs
# ============================================================================

output "nfs_id" {
  description = "NFS server VM ID"
  value       = module.nfs_vm.vm_ids[0]
}

output "nfs_name" {
  description = "NFS server VM name"
  value       = module.nfs_vm.vm_names[0]
}

output "nfs_ip" {
  description = "NFS server IP address"
  value       = module.nfs_vm.vm_ip_addresses[0]
}
