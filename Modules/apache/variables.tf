# ============================================================================
# Module: Apache Reverse Proxy - Variables
# ============================================================================

variable "instance_count" {
  description = "Number of Apache reverse proxy instances"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Number of CPUs per instance"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory in MB per instance"
  type        = number
  default     = 2048
}

variable "environment" {
  description = "Target environment"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "datacenter_id" {
  description = "vSphere datacenter ID"
  type        = string
}

variable "cluster_id" {
  description = "vSphere compute cluster ID"
  type        = string
}

variable "datastore_id" {
  description = "vSphere datastore ID"
  type        = string
}

variable "network_id" {
  description = "vSphere network ID"
  type        = string
}

variable "vm_template" {
  description = "VM template to clone from"
  type        = string
  default     = "rhel8-template"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
