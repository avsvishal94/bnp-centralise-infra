# ============================================================================
# Terraform Module: NSX-T Firewall - Variables
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
