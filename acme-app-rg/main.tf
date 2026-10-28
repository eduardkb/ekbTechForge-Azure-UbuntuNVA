resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  default_outbound_access_enabled = false
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # security_rule {
  #   name                       = "Allow-VNet-ICMP-In"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Icmp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "VirtualNetwork"
  #   destination_address_prefix = "VirtualNetwork"
  # }

  # security_rule {
  #   name                       = "Allow-VNet-HTTP-In"
  #   priority                   = 110
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "80"
  #   source_address_prefix      = "VirtualNetwork"
  #   destination_address_prefix = "VirtualNetwork"
  # }

  # security_rule {
  #   name                       = "Deny-All-In"
  #   priority                   = 4096
  #   direction                  = "Inbound"
  #   access                     = "Deny"
  #   protocol                   = "*"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  # security_rule {
  #   name                       = "Allow-VNet-ICMP-Out"
  #   priority                   = 100
  #   direction                  = "Outbound"
  #   access                     = "Allow"
  #   protocol                   = "Icmp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "VirtualNetwork"
  #   destination_address_prefix = "VirtualNetwork"
  # }

  # security_rule {
  #   name                       = "Allow-VNet-HTTP-Out"
  #   priority                   = 110
  #   direction                  = "Outbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "80"
  #   source_address_prefix      = "VirtualNetwork"
  #   destination_address_prefix = "VirtualNetwork"
  # }

  # security_rule {
  #   name                       = "Deny-All-Out"
  #   priority                   = 4096
  #   direction                  = "Outbound"
  #   access                     = "Deny"
  #   protocol                   = "*"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_route_table" "route_table" {
  name                = "${var.name_prefix}-rt"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  route {
    name                    = "toInternet"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = var.nva_private_ip
  }

  route {
    name                    = "toDataVnet"
    address_prefix          = var.data_vnet_cidr
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = var.nva_private_ip
  }

  tags              = var.tags
}

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = azurerm_subnet.this.id
  route_table_id = azurerm_route_table.route_table.id
}


data "azurerm_virtual_network" "hub" {
  provider            = azurerm.hub
  name                = var.hub_virtual_network_name
  resource_group_name = var.hub_resource_group_name
}

resource "azurerm_virtual_network_peering" "workload_to_hub" {
  name                      = "${var.name_prefix}-to-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_workload" {
  provider                  = azurerm.hub
  name                      = substr("${var.hub_virtual_network_name}-to-${var.name_prefix}", 0, 80)
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.this.id
  allow_forwarded_traffic   = true
  allow_virtual_network_access = true
}

resource "azurerm_network_interface" "this" {
  count               = var.deploy_vm ? 1 : 0
  name                = "${var.name_prefix}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count                           = var.deploy_vm ? 1 : 0
  name                            = "${var.name_prefix}-vm"
  computer_name                   = "${var.name_prefix}-vm"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.this[0].id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  count              = var.deploy_vm ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.this[0].id
  location           = azurerm_resource_group.this.location
  enabled            = true
  tags               = var.tags

  daily_recurrence_time = "1800"
  timezone              = "E. South America Standard Time"

  notification_settings {
    enabled = false
  }
}

# Network Watcher
data "azurerm_network_watcher" "central" {
  provider            = azurerm.hub
  name                = var.network_watcher_name
  resource_group_name = var.network_watcher_resource_group_name
}

data "azurerm_storage_account" "central" {
  provider            = azurerm.hub
  name                = var.flow_logs_storage_account_name
  resource_group_name = var.flow_logs_storage_account_resource_group_name
}

resource "azurerm_network_watcher_flow_log" "this" {
  name                 = "${var.name_prefix}-vnet-flow-log"
  network_watcher_name = data.azurerm_network_watcher.central.name
  resource_group_name  = data.azurerm_network_watcher.central.resource_group_name
  location             = data.azurerm_network_watcher.central.location

  target_resource_id = azurerm_virtual_network.this.id
  storage_account_id = data.azurerm_storage_account.central.id

  enabled = true
  version = 2

  retention_policy {
    enabled = true
    days    = 7
  }
}