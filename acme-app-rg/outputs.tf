output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "Created resource group name."
}

output "vm_private_ip_address" {
  value       = var.deploy_vm ? azurerm_network_interface.this[0].private_ip_address : null
  description = "Private IP address of the Ubuntu VM."
}

output "vm_id" {
  value       = var.deploy_vm ? azurerm_linux_virtual_machine.this[0].id : null
  description = "Azure resource ID of the Ubuntu VM."
}
