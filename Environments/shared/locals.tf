# ============================================================================
# Shared Locals - Common values across all environments
# ============================================================================

locals {
  # Ecosystem and application metadata
  ecosystem   = var.ecosystem
  app_name    = var.app_name
  environment = var.environment

  # Common tags applied to all resources
  common_tags = {
    managed_by  = "terraform"
    ecosystem   = var.ecosystem
    application = var.app_name
    environment = var.environment
    owner       = "sre-team"
  }

  # Artifactory state path convention:
  #   terraform-state/<ecosystem>/<app>/<env>/terraform.tfstate
  state_path = "terraform-state/${var.ecosystem}/${var.app_name}/${var.environment}/terraform.tfstate"

  # vSphere datacenter and cluster mapping per environment
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_datastore  = var.vsphere_datastore
  vsphere_network    = var.vsphere_network
}
