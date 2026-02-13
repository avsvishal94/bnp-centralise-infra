# ============================================================================
# Main Infrastructure Definition
# ============================================================================
# Provisions the full application stack using SRE-managed Terraform modules:
#   - NSX-T Firewall (ports 443, 80)
#   - HAProxy Load Balancer (1x)
#   - Apache HTTPD 2.4 Reverse Proxies (2x)
#   - Java/Dataframe App Servers (4x)
#   - NFS Data Server (/mnt/data)
#   - NFS Binary Server (/mnt/binaries)
# ============================================================================

# ---- NSX-T Firewall Rules ----
module "firewall" {
  source = "artifactory.cib.echonet/artifactory/terraform-modules/modules/nsx-firewall"

  app_name    = var.app_name
  environment = var.env
  ecosystem   = var.ecosystem
}

# ---- Load Balancer - HAProxy ----
module "load_balancer" {
  source = "artifactory.cib.echonet/artifactory/terraform-modules/modules/haproxy-lb"

  app_name      = var.app_name
  environment   = var.env
  ecosystem     = var.ecosystem
  memory_mb     = var.lb_memory_mb
  datacenter    = var.datacenter
  datastore     = var.datastore
  cluster       = var.cluster
  network       = var.network
  template_name = var.template_name
  folder        = var.folder
}

# ---- Reverse Proxies - Apache HTTPD 2.4 ----
module "reverse_proxies" {
  source = "artifactory.cib.echonet/artifactory/terraform-modules/modules/vsphere-vm"

  name_prefix    = "rp-${var.app_name}"
  environment    = var.env
  ecosystem      = var.ecosystem
  instance_count = 2
  num_cpus       = 1
  memory_mb      = var.rp_memory_mb
  datacenter     = var.datacenter
  datastore      = var.datastore
  cluster        = var.cluster
  network        = var.network
  template_name  = var.template_name
  folder         = var.folder
}

# ---- Application Servers - Java/Dataframe ----
module "app_servers" {
  source = "artifactory.cib.echonet/artifactory/terraform-modules/modules/vsphere-vm"

  name_prefix    = "app-${var.app_name}"
  environment    = var.env
  ecosystem      = var.ecosystem
  instance_count = 4
  num_cpus       = 1
  memory_mb      = var.app_memory_mb
  disk_size_gb   = var.app_disk_gb
  datacenter     = var.datacenter
  datastore      = var.datastore
  cluster        = var.cluster
  network        = var.network
  template_name  = var.template_name
  folder         = var.folder
}

# ---- NFS Data Server ----
module "nfs_data" {
  source = "artifactory.cib.echonet/artifactory/terraform-modules/modules/nfs-server"

  app_name      = var.app_name
  environment   = var.env
  ecosystem     = var.ecosystem
  nfs_type      = "data"
  mount_path    = "/mnt/data"
  disk_size_gb  = var.nfs_data_disk_gb
  datacenter    = var.datacenter
  datastore     = var.datastore
  cluster       = var.cluster
  network       = var.network
  template_name = var.template_name
  folder        = var.folder
}

# ---- NFS Binary Server ----
module "nfs_binaries" {
  source = "artifactory.cib.echonet/artifactory/terraform-modules/modules/nfs-server"

  app_name      = var.app_name
  environment   = var.env
  ecosystem     = var.ecosystem
  nfs_type      = "binaries"
  mount_path    = "/mnt/binaries"
  disk_size_gb  = var.nfs_bin_disk_gb
  datacenter    = var.datacenter
  datastore     = var.datastore
  cluster       = var.cluster
  network       = var.network
  template_name = var.template_name
  folder        = var.folder
}
