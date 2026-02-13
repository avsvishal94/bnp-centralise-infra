# ============================================================================
# UAT Environment - Variable Overrides
# ============================================================================

environment = "uat"
ecosystem   = "PB-GLOBALPRIMEDB"
app_name    = "centralise-infra"

# vSphere
vsphere_server     = "vcenter-uat.cib.echonet"
vsphere_datacenter = "DC-UAT"
vsphere_cluster    = "CL-UAT-01"
vsphere_datastore  = "DS-UAT-01"
vsphere_network    = "VLAN-UAT-100"
vm_template        = "rhel8-template"

# Apache Reverse Proxy
apache_instance_count = 2
apache_cpu            = 1
apache_memory_mb      = 4096

# Red Hat VM (App Servers)
redhatvm_instance_count = 4
redhatvm_cpu            = 2
redhatvm_memory_mb      = 4096
redhatvm_disk_gb        = 50
