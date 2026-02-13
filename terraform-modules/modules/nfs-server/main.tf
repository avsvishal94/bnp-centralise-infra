# ============================================================================
# Terraform Module: NFS Server
# ============================================================================
# Provisions NFS server VMs for data and binary storage.
# Supports encrypted storage at rest with daily backup configuration.
# ============================================================================

module "nfs_vm" {
  source = "../vsphere-vm"

  name_prefix    = "nfs-${var.nfs_type}-${var.app_name}"
  environment    = var.environment
  ecosystem      = var.ecosystem
  instance_count = 1
  num_cpus       = var.num_cpus
  memory_mb      = var.memory_mb
  disk_size_gb   = var.disk_size_gb
  datacenter     = var.datacenter
  datastore      = var.datastore
  cluster        = var.cluster
  network        = var.network
  template_name  = var.template_name
  folder         = var.folder
  ip_addresses   = var.nfs_ip_address != "" ? [var.nfs_ip_address] : null
  netmask        = var.netmask
  gateway        = var.gateway
}
