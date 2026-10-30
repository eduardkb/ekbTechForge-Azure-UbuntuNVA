hub_subscription_id                     = "8f4f93d3-a1e9-4e95-9622-f9c978e5d78f"
hub_virtual_network_resource_group_name = "rg-platform-connectivity"
hub_virtual_network_name                = "vnet-platform-hub"
hub_subnet_name                         = "snet-shared-services"
private_dns_zone_name                   = "acme.internal"

resource_group_name   = "rg-hub-nva"
location              = "southcentralus"
name_prefix           = "hubnva"
admin_ssh_public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjOxIfF/4Dx9tbUVS+0fJFpMOEHdgiJq+vzeGGSQ5Qb azure-vm"
vm_private_ip_address = "10.0.1.10"
# SIZES:
#       Standard_B2ts_v2    = 2vcpu 1ram  = USD 0.0125
#       Standard_B2ls_v2    = 2vcpu 4ram  = USD 0.0499
#       Standard_B2s_v2     = 2vcpu 8ram  = USD 0.0998
vm_size   = "Standard_B2ts_v2"