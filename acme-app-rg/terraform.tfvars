subscription_id      = "44e8b0e3-4753-4e9d-9ed6-a87c6bf5c96f"
admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjOxIfF/4Dx9tbUVS+0fJFpMOEHdgiJq+vzeGGSQ5Qb azure-vm"

hub_subscription_id      = "8f4f93d3-a1e9-4e95-9622-f9c978e5d78f"
hub_resource_group_name  = "rg-platform-connectivity"
hub_virtual_network_name = "vnet-platform-hub"

resource_group_name = "rg-application"
name_prefix         = "acmeapp"

# SIZES:
#       Standard_B2ts_v2    = 2vcpu 1ram  = USD 0.0125
#       Standard_B2ls_v2    = 2vcpu 4ram  = USD 0.0499
#       Standard_B2s_v2     = 2vcpu 8ram  = USD 0.0998
vm_size   = "Standard_B2ts_v2"
deploy_vm = true

# variables for custom route table
nva_private_ip  = "10.0.1.10"
data_vnet_cidr   = "10.30.1.0/24"

# variables to create centralized network flow log for acme-app vnet
network_watcher_name                            = "NetworkWatcher_southcentralus"
network_watcher_resource_group_name             = "NetworkWatcherRG"
flow_logs_storage_account_name                  = "stplatnetlogs0001"
flow_logs_storage_account_resource_group_name   = "rg-platform-connectivity"

# private DNS - create link to acme-hub-rg's private dns zone
hub_nva_resource_group_name = "rg-hub-nva"
private_dns_zone_name       = "acme.internal"