# ============================================================================
# Terraform Variables - Pipeline-Injected and User-Defined
# ============================================================================
# Variables injected by Jenkins pipeline (TF_VAR_*) and configurable
# by the application team.
# ============================================================================

# ---- Pipeline-Injected Variables ----

variable "env" {
  description = "Target environment (dev, stg, pt, qa)"
  type        = string
}

variable "ecosystem" {
  description = "Ecosystem name (e.g., PB-GLOBALPRIMEDB, Puma)"
  type        = string
}

# ---- vSphere Connection ----

variable "vsphere_server" {
  description = "vSphere server hostname"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

# ---- NSX-T Connection ----

variable "nsxt_host" {
  description = "NSX-T Manager hostname"
  type        = string
}

variable "nsxt_username" {
  description = "NSX-T username"
  type        = string
}

variable "nsxt_password" {
  description = "NSX-T password"
  type        = string
  sensitive   = true
}

# ---- Infrastructure Configuration ----

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore name"
  type        = string
}

variable "cluster" {
  description = "vSphere compute cluster name"
  type        = string
}

variable "network" {
  description = "vSphere network name"
  type        = string
}

variable "template_name" {
  description = "vSphere VM template to clone from"
  type        = string
}

variable "folder" {
  description = "vSphere folder for VMs"
  type        = string
  default     = ""
}

# ---- Resource Sizing ----

variable "lb_memory_mb" {
  description = "Memory for HAProxy load balancer (MB)"
  type        = number
  default     = 2048
}

variable "rp_memory_mb" {
  description = "Memory per Apache reverse proxy (MB)"
  type        = number
  default     = 2048
}

variable "app_memory_mb" {
  description = "Memory per application server (MB)"
  type        = number
  default     = 4096
}

variable "app_disk_gb" {
  description = "Disk size per application server (GB)"
  type        = number
  default     = 50
}

variable "nfs_data_disk_gb" {
  description = "Disk size for NFS data server (GB)"
  type        = number
  default     = 200
}

variable "nfs_bin_disk_gb" {
  description = "Disk size for NFS binary server (GB)"
  type        = number
  default     = 100
}
