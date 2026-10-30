output "resource_group_name" {
  description = "Name of the resource group created for the NVA."
  value       = azurerm_resource_group.hub_nva.name
}

output "vm_id" {
  description = "Resource ID of the Ubuntu NVA virtual machine."
  value       = azurerm_linux_virtual_machine.nva.id
}

output "vm_private_ip_address" {
  description = "Static private IPv4 address used by the NVA for spoke next-hop and outbound NAT."
  value       = azurerm_network_interface.nva.private_ip_address
}

output "load_balancer_public_ip_address" {
  description = "Static public IPv4 address used by the Load Balancer for outbound SNAT."
  value       = azurerm_public_ip.load_balancer.ip_address
}

output "hub_subnet_id" {
  description = "ID of the existing hub subnet hosting the NVA."
  value       = data.azurerm_subnet.hub.id
}

output "private_dns_zone_name" {
  description = "Private DNS zone where VMs of all three VNets auto-register."
  value       = azurerm_private_dns_zone.internal.name
}

output "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone."
  value       = azurerm_private_dns_zone.internal.id
}