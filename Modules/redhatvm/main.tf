# ============================================================================
# Module: Red Hat VM (Application Servers)
# ============================================================================
# Provisions RHEL-based application server VMs on vSphere.
# These run the Java/Dataframe workloads behind the Apache reverse proxies.
# ============================================================================

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = var.datacenter_id
}

resource "vsphere_virtual_machine" "redhatvm" {
  count = var.instance_count

  name             = "${var.app_name}-app-${var.environment}-${count.index + 1}"
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
    size             = var.disk_gb
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  lifecycle {
    ignore_changes = [annotation]
  }
}
