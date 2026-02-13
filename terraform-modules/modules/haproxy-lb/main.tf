# ============================================================================
# Terraform Module: HAProxy Load Balancer
# ============================================================================
# Provisions an HAProxy load balancer VM using the base vsphere-vm module.
# Tagged as terraform-managed for identification.
# ============================================================================

module "lb_vm" {
  source = "../vsphere-vm"

  name_prefix    = "lb-${var.app_name}"
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
  ip_addresses   = var.lb_ip_address != "" ? [var.lb_ip_address] : null
  netmask        = var.netmask
  gateway        = var.gateway
}
