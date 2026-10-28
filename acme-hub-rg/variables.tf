variable "hub_subscription_id" {
  description = "Subscription ID containing the existing hub VNet and the new NVA resources."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.hub_subscription_id))
    error_message = "hub_subscription_id must be a UUID."
  }
}

variable "hub_virtual_network_resource_group_name" {
  description = "Resource group containing the existing hub VNet and subnet."
  type        = string
}

variable "hub_virtual_network_name" {
  description = "Name of the existing hub VNet."
  type        = string
}

variable "hub_subnet_name" {
  description = "Name of the existing hub subnet that will contain the NVA NIC."
  type        = string
}

variable "resource_group_name" {
  description = "Name for the new resource group containing the NVA resources."
  type        = string
}

variable "location" {
  description = "Azure region for the new resource group and NVA resources; use the hub VNet region."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Lowercase prefix used for the NVA VM, NIC, and public IP names."
  type        = string
  default     = "acme-hub-nva"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,20}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and be at most 21 characters."
  }
}

variable "vm_private_ip_address" {
  description = "Unused static IPv4 address from the existing hub subnet's address range."
  type        = string

  validation {
    condition     = can(cidrhost("${var.vm_private_ip_address}/32", 0))
    error_message = "vm_private_ip_address must be a valid IPv4 address."
  }
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_ssh_public_key" {
  description = "OpenSSH public key for VM administration; never provide the private key."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519|ecdsa) ", var.admin_ssh_public_key))
    error_message = "admin_ssh_public_key must be an OpenSSH RSA, Ed25519, or ECDSA public key."
  }
}

variable "ubuntu_image_version" {
  description = "Version of the Canonical Ubuntu 24.04 LTS server image."
  type        = string
  default     = "latest"
}

variable "os_disk_storage_account_type" {
  description = "Managed disk storage SKU for the OS disk."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GiB."
  type        = number
  default     = 30

  validation {
    condition     = var.os_disk_size_gb >= 30
    error_message = "os_disk_size_gb must be at least 30 GiB for the selected Ubuntu image."
  }
}

variable "nat_excluded_cidrs" {
  description = "IPv4 destination ranges that must not be source-NATed. Add every spoke and other internal range, especially if it is not RFC1918."
  type        = list(string)
  default = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]

  validation {
    condition     = alltrue([for cidr in var.nat_excluded_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every nat_excluded_cidrs entry must be a valid IPv4 CIDR range."
  }
}

variable "tags" {
  description = "Tags applied to the new resource group and NVA resources."
  type        = map(string)
  default = {
    CostCenter  = "CC-0001"
    Environment = "Production"
    Owner       = "ekbTFConn@gmail.com"
  }
}

variable "admin_username" {
  description = "Linux administrator account name. Password authentication is disabled."
  type        = string
  default     = "azuser"
}

variable "admin_password" {
  description = "Administrator password for the Linux VM"
  type        = string
  sensitive   = true
  default     = "AzUserP@ss01"
}