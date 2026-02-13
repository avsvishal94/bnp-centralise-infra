# ============================================================================
# Terraform Module: NFS Server - Variables
# ============================================================================

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Target environment (dev, stg, pt, qa)"
  type        = string
}

variable "ecosystem" {
  description = "Ecosystem name"
  type        = string
}

variable "nfs_type" {
  description = "NFS server type: data or binaries"
  type        = string
  validation {
    condition     = contains(["data", "binaries"], var.nfs_type)
    error_message = "nfs_type must be either 'data' or 'binaries'."
  }
}

variable "mount_path" {
  description = "NFS export mount path (e.g., /mnt/data or /mnt/binaries)"
  type        = string
}

variable "num_cpus" {
  description = "Number of CPUs"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 100
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
  description = "vSphere folder"
  type        = string
  default     = ""
}

variable "nfs_ip_address" {
  description = "Static IP for the NFS server (empty for DHCP)"
  type        = string
  default     = ""
}

variable "netmask" {
  description = "Network mask bits"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Default gateway IP"
  type        = string
  default     = ""
}
