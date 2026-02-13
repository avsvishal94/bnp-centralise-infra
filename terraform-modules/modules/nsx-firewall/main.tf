# ============================================================================
# Terraform Module: NSX-T Firewall Rules
# ============================================================================
# Provisions NSX-T security policies and firewall rules for the
# application environment. Restricts ingress to ports 443 (HTTPS)
# and 80 (HTTP).
# ============================================================================

resource "nsxt_policy_group" "app_servers" {
  display_name = "app-servers-${var.app_name}-${var.environment}"
  description  = "Application server group for ${var.app_name} in ${var.environment}"

  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = "environment:${var.environment}"
    }
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = "ecosystem:${var.ecosystem}"
    }
  }
}

resource "nsxt_policy_service" "https" {
  display_name = "HTTPS-${var.app_name}-${var.environment}"

  l4_port_set_entry {
    display_name      = "HTTPS"
    protocol          = "TCP"
    destination_ports = ["443"]
  }
}

resource "nsxt_policy_service" "http" {
  display_name = "HTTP-${var.app_name}-${var.environment}"

  l4_port_set_entry {
    display_name      = "HTTP"
    protocol          = "TCP"
    destination_ports = ["80"]
  }
}

resource "nsxt_policy_security_policy" "firewall" {
  display_name = "fw-${var.app_name}-${var.environment}"
  description  = "Firewall policy for ${var.app_name} in ${var.environment}"
  category     = "Application"

  rule {
    display_name       = "allow-https"
    destination_groups = [nsxt_policy_group.app_servers.path]
    services           = [nsxt_policy_service.https.path]
    action             = "ALLOW"
    logged             = true
  }

  rule {
    display_name       = "allow-http"
    destination_groups = [nsxt_policy_group.app_servers.path]
    services           = [nsxt_policy_service.http.path]
    action             = "ALLOW"
    logged             = true
  }

  rule {
    display_name       = "deny-all"
    destination_groups = [nsxt_policy_group.app_servers.path]
    action             = "DROP"
    logged             = true
  }
}
