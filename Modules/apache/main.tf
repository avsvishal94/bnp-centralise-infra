# ============================================================================
# Module: Apache Reverse Proxy (HTTPD 2.4)
# ============================================================================
# Provisions Apache HTTPD 2.4 reverse proxy VMs on vSphere.
# These sit behind the HAProxy load balancer and forward traffic
# to the application servers.
# ============================================================================

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = var.datacenter_id
}

resource "vsphere_virtual_machine" "apache" {
  count = var.instance_count

  name             = "${var.app_name}-apache-${var.environment}-${count.index + 1}"
  resource_pool_id = var.cluster_id
  datastore_id     = var.datastore_id
  num_cpus         = var.cpu
  memory           = var.memory_mb
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  firmware         = data.vsphere_virtual_machine.template.firmware

  network_interface {
    network_id   = var.network_id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  lifecycle {
    ignore_changes = [annotation]
  }
}
