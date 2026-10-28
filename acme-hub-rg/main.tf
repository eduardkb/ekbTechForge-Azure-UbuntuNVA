data "azurerm_virtual_network" "hub" {
  name                = var.hub_virtual_network_name
  resource_group_name = var.hub_virtual_network_resource_group_name
}

data "azurerm_subnet" "hub" {
  name                 = var.hub_subnet_name
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name  = var.hub_virtual_network_resource_group_name
}

resource "azurerm_resource_group" "hub_nva" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_network_security_group" "hub_subnet" {
  name                = "${var.name_prefix}-subnet-nsg"
  location            = azurerm_resource_group.hub_nva.location
  resource_group_name = azurerm_resource_group.hub_nva.name
  tags                = var.tags

  # security_rule {
  #   name                       = "Deny-All-Inbound"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Deny"
  #   protocol                   = "*"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  security_rule {
    name                       = "Allow-Internet-Egress"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  # security_rule {
  #   name                       = "Deny-All-Other-Outbound"
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

resource "azurerm_subnet_network_security_group_association" "hub_subnet" {
  subnet_id                 = data.azurerm_subnet.hub.id
  network_security_group_id = azurerm_network_security_group.hub_subnet.id
}

resource "azurerm_public_ip" "load_balancer" {
  name                = "${var.name_prefix}-pip"
  location            = azurerm_resource_group.hub_nva.location
  resource_group_name = azurerm_resource_group.hub_nva.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
  tags                = var.tags
}

resource "azurerm_lb" "nva" {
  name                = "${var.name_prefix}-lb"
  location            = azurerm_resource_group.hub_nva.location
  resource_group_name = azurerm_resource_group.hub_nva.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.load_balancer.id
  }
}

resource "azurerm_lb_backend_address_pool" "nva" {
  name            = "${var.name_prefix}-backend-pool"
  loadbalancer_id = azurerm_lb.nva.id
}

resource "azurerm_network_interface" "nva" {
  name                  = "${var.name_prefix}-nic"
  location              = azurerm_resource_group.hub_nva.location
  resource_group_name   = azurerm_resource_group.hub_nva.name
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.hub.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ip_address
    primary                       = true
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nva" {
  network_interface_id    = azurerm_network_interface.nva.id
  ip_configuration_name   = "primary"
  backend_address_pool_id = azurerm_lb_backend_address_pool.nva.id
}

resource "azurerm_lb_outbound_rule" "nva" {
  name                    = "${var.name_prefix}-outbound"
  loadbalancer_id         = azurerm_lb.nva.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.nva.id

  frontend_ip_configuration {
    name = "public"
  }
}

resource "azurerm_linux_virtual_machine" "nva" {
  name                            = "${var.name_prefix}-vm"
  computer_name                   = "${var.name_prefix}-vm"
  location                        = azurerm_resource_group.hub_nva.location
  resource_group_name             = azurerm_resource_group.hub_nva.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nva.id]
  custom_data = base64encode(file("${path.module}/cloud-init.sh"))
  tags = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = var.ubuntu_image_version
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  virtual_machine_id = azurerm_linux_virtual_machine.nva.id
  location           = azurerm_resource_group.hub_nva.location
  enabled            = true
  tags               = var.tags

  daily_recurrence_time = "1800"
  timezone              = "E. South America Standard Time"

  notification_settings {
    enabled = false
  }
}