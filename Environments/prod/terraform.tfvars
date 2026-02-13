# ============================================================================
# PROD Environment - Variable Overrides
# ============================================================================

environment = "prod"
ecosystem   = "PB-GLOBALPRIMEDB"
app_name    = "centralise-infra"

# vSphere
vsphere_server     = "vcenter-prod.cib.echonet"
vsphere_datacenter = "DC-PROD"
vsphere_cluster    = "CL-PROD-01"
vsphere_datastore  = "DS-PROD-01"
vsphere_network    = "VLAN-PROD-100"
vm_template        = "rhel8-template"

# Apache Reverse Proxy
apache_instance_count = 2
apache_cpu            = 2
apache_memory_mb      = 4096

# Red Hat VM (App Servers)
redhatvm_instance_count = 4
redhatvm_cpu            = 2
redhatvm_memory_mb      = 8192
redhatvm_disk_gb        = 100
