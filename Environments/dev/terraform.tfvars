# ============================================================================
# DEV Environment - Variable Overrides
# ============================================================================

environment = "dev"
ecosystem   = "PB-GLOBALPRIMEDB"
app_name    = "centralise-infra"

# vSphere
vsphere_server     = "vcenter-dev.cib.echonet"
vsphere_datacenter = "DC-DEV"
vsphere_cluster    = "CL-DEV-01"
vsphere_datastore  = "DS-DEV-01"
vsphere_network    = "VLAN-DEV-100"
vm_template        = "rhel8-template"

# Apache Reverse Proxy
apache_instance_count = 1
apache_cpu            = 1
apache_memory_mb      = 2048

# Red Hat VM (App Servers)
redhatvm_instance_count = 2
redhatvm_cpu            = 1
redhatvm_memory_mb      = 2048
redhatvm_disk_gb        = 40
