# ============================================================================
# Shared Main - Provider configuration and module calls
# ============================================================================
# State path convention:
#   terraform-state/<ecosystem>/<app>/<env>/terraform.tfstate
# ============================================================================

terraform {
  # JFrog Artifactory Backend for remote state storage
  backend "artifactory" {
    url     = "https://artifactory.cib.echonet/artifactory"
    repo    = "terraform-state"
    subpath = "" # Overridden at runtime: <ecosystem>/<app>/<env>
  }

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.3.0"
}

# ---- vSphere Provider ----
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = false
}

# ---- Data Sources ----
data "vsphere_datacenter" "dc" {
  name = local.vsphere_datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = local.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = local.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = local.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# ---- Module: Apache Reverse Proxy ----
module "apache" {
  source = "../../Modules/apache"

  instance_count = var.apache_instance_count
  cpu            = var.apache_cpu
  memory_mb      = var.apache_memory_mb
  environment    = var.environment
  app_name       = var.app_name

  datacenter_id   = data.vsphere_datacenter.dc.id
  cluster_id      = data.vsphere_compute_cluster.cluster.id
  datastore_id    = data.vsphere_datastore.datastore.id
  network_id      = data.vsphere_network.network.id
  vm_template     = var.vm_template

  tags = local.common_tags
}

# ---- Module: Red Hat VM (App Servers) ----
module "redhatvm" {
  source = "../../Modules/redhatvm"

  instance_count = var.redhatvm_instance_count
  cpu            = var.redhatvm_cpu
  memory_mb      = var.redhatvm_memory_mb
  disk_gb        = var.redhatvm_disk_gb
  environment    = var.environment
  app_name       = var.app_name

  datacenter_id   = data.vsphere_datacenter.dc.id
  cluster_id      = data.vsphere_compute_cluster.cluster.id
  datastore_id    = data.vsphere_datastore.datastore.id
  network_id      = data.vsphere_network.network.id
  vm_template     = var.vm_template

  tags = local.common_tags
}
