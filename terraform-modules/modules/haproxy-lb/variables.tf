# ============================================================================
# Terraform Module: HAProxy Load Balancer - Variables
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
  description = "vSphere folder"
  type        = string
  default     = ""
}

variable "lb_ip_address" {
  description = "Static IP for the load balancer (empty for DHCP)"
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
