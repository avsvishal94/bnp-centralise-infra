# ============================================================================
# Terraform Module: vSphere Virtual Machine
# ============================================================================
# Reusable module for provisioning VMs on VMware vSphere.
# Published to Artifactory Module Registry for consumption by app teams.
# ============================================================================

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  count            = var.instance_count
  name             = "${var.name_prefix}-${count.index + 1}-${var.environment}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.folder

  num_cpus = var.num_cpus
  memory   = var.memory_mb
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.disk_size_gb
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.name_prefix}-${count.index + 1}-${var.environment}"
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.ip_addresses != null ? var.ip_addresses[count.index] : null
        ipv4_netmask = var.netmask
      }

      ipv4_gateway = var.gateway
    }
  }

  tags = [
    "terraform-managed",
    "environment:${var.environment}",
    "ecosystem:${var.ecosystem}"
  ]
}
