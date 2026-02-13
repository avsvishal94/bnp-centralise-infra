# ============================================================================
# Shared Variables - Input variables used across all environments
# ============================================================================

# ---- General ----
variable "ecosystem" {
  description = "Ecosystem name (e.g., PB-GLOBALPRIMEDB, Puma)"
  type        = string
}

variable "app_name" {
  description = "Application name for resource naming and state path"
  type        = string
}

variable "environment" {
  description = "Target environment (dev, stg, qa, uat, prod)"
  type        = string
}

# ---- vSphere Infrastructure ----
variable "vsphere_server" {
  description = "vSphere vCenter server address"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "vsphere_cluster" {
  description = "vSphere compute cluster name"
  type        = string
}

variable "vsphere_datastore" {
  description = "vSphere datastore name"
  type        = string
}

variable "vsphere_network" {
  description = "vSphere network/port group name"
  type        = string
}

variable "vm_template" {
  description = "vSphere VM template to clone from"
  type        = string
  default     = "rhel8-template"
}

# ---- Apache Reverse Proxy ----
variable "apache_instance_count" {
  description = "Number of Apache reverse proxy instances"
  type        = number
  default     = 2
}

variable "apache_cpu" {
  description = "Number of CPUs for Apache instances"
  type        = number
  default     = 1
}

variable "apache_memory_mb" {
  description = "Memory in MB for Apache instances"
  type        = number
  default     = 2048
}

# ---- Red Hat VM (App Servers) ----
variable "redhatvm_instance_count" {
  description = "Number of Red Hat VM application server instances"
  type        = number
  default     = 4
}

variable "redhatvm_cpu" {
  description = "Number of CPUs for Red Hat VM instances"
  type        = number
  default     = 1
}

variable "redhatvm_memory_mb" {
  description = "Memory in MB for Red Hat VM instances"
  type        = number
  default     = 4096
}

variable "redhatvm_disk_gb" {
  description = "Disk size in GB for Red Hat VM instances"
  type        = number
  default     = 50
}

# ---- JFrog Artifactory Backend ----
variable "artifactory_url" {
  description = "JFrog Artifactory base URL"
  type        = string
  default     = "https://artifactory.cib.echonet/artifactory"
}

variable "artifactory_repo" {
  description = "Artifactory repository for Terraform state"
  type        = string
  default     = "terraform-state"
}
