# ============================================================================
# Terraform Module: vSphere VM - Variables
# ============================================================================

variable "name_prefix" {
  description = "Prefix for VM names (e.g., app, rp, lb)"
  type        = string
}

variable "environment" {
  description = "Target environment (dev, stg, pt, qa)"
  type        = string
}

variable "ecosystem" {
  description = "Ecosystem name (e.g., PB-GLOBALPRIMEDB)"
  type        = string
}

variable "instance_count" {
  description = "Number of VM instances to create"
  type        = number
  default     = 1
}

variable "num_cpus" {
  description = "Number of CPUs per VM"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory in MB per VM"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 50
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
  description = "vSphere folder for the VMs"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domain name for VM customization"
  type        = string
  default     = "cib.echonet"
}

variable "ip_addresses" {
  description = "List of static IP addresses (one per instance). Null for DHCP."
  type        = list(string)
  default     = null
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
