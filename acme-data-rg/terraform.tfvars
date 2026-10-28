subscription_id      = "be6b2fa1-9140-42d7-a378-a4d089e7ec7b"
admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMjOxIfF/4Dx9tbUVS+0fJFpMOEHdgiJq+vzeGGSQ5Qb azure-vm"

hub_subscription_id      = "8f4f93d3-a1e9-4e95-9622-f9c978e5d78f"
hub_resource_group_name  = "rg-platform-connectivity"
hub_virtual_network_name = "vnet-platform-hub"

resource_group_name = "rg-data"
name_prefix         = "acmedata"
 
# SIZES:
#       Standard_B2ts_v2    = 2vcpu 1ram  = USD 0.0125
#       Standard_B2ls_v2    = 2vcpu 4ram  = USD 0.0499
#       Standard_B2s_v2     = 2vcpu 8ram  = USD 0.0998
vm_size   = "Standard_B2ts_v2"
deploy_vm = true

# variables for custom route table
nva_private_ip  = "10.0.1.10"
app_vnet_cidr   = "10.20.1.0/24"
