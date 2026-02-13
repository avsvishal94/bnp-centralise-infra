# ============================================================================
# Terraform Backend Configuration
# ============================================================================
# Remote backend using Artifactory for state management.
# State files are stored per application per environment.
# ============================================================================

terraform {
  backend "artifactory" {
    url     = "https://artifactory.cib.echonet/artifactory"
    repo    = "terraform-statefiles"
    subpath = "<app-name>/${var.env}"
  }

  required_version = ">= 1.5.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
  }
}

provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = false
}

provider "nsxt" {
  host                 = var.nsxt_host
  username             = var.nsxt_username
  password             = var.nsxt_password
  allow_unverified_ssl = false
}
