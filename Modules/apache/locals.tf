# ============================================================================
# Module: Apache Reverse Proxy - Locals
# ============================================================================

locals {
  apache_name_prefix = "${var.app_name}-apache-${var.environment}"
}
