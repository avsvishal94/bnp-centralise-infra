# ============================================================================
# STG Environment - Variable Overrides
# ============================================================================

environment = "stg"
ecosystem   = "PB-GLOBALPRIMEDB"
app_name    = "centralise-infra"

# vSphere
vsphere_server     = "vcenter-stg.cib.echonet"
vsphere_datacenter = "DC-STG"
vsphere_cluster    = "CL-STG-01"
vsphere_datastore  = "DS-STG-01"
vsphere_network    = "VLAN-STG-100"
vm_template        = "rhel8-template"

# Apache Reverse Proxy
apache_instance_count = 2
apache_cpu            = 1
apache_memory_mb      = 2048

# Red Hat VM (App Servers)
redhatvm_instance_count = 2
redhatvm_cpu            = 1
redhatvm_memory_mb      = 4096
redhatvm_disk_gb        = 50
