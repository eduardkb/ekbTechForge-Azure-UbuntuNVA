variable "subscription_id" {
  description = "ID of the existing Azure subscription in which resources are created."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "hub_subscription_id" {
  description = "ID of the platform connectivity subscription containing the hub VNet."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.hub_subscription_id))
    error_message = "hub_subscription_id must be a UUID."
  }
}

variable "hub_resource_group_name" {
  description = "Resource group containing the existing hub VNet."
  type        = string

  validation {
    condition     = length(trimspace(var.hub_resource_group_name)) > 0
    error_message = "hub_resource_group_name must not be empty."
  }
}

variable "hub_virtual_network_name" {
  description = "Name of the existing hub virtual network in the platform connectivity subscription."
  type        = string

  validation {
    condition     = length(trimspace(var.hub_virtual_network_name)) > 0
    error_message = "hub_virtual_network_name must not be empty."
  }
}

variable "resource_group_name" {
  description = "Name for the workload resource group."
  type        = string
  default     = "rg-ubuntu-southcentralus"
}

variable "location" {
  description = "Azure region for workload resources."
  type        = string
  default     = "southcentralus"

  validation {
    condition     = lower(var.location) == "southcentralus"
    error_message = "This configuration is intentionally scoped to South Central US."
  }
}

variable "name_prefix" {
  description = "Short lowercase prefix used in resource names (1-15 characters)."
  type        = string
  default     = "ubuntu"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,14}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain only lowercase letters, digits, and hyphens."
  }
}

variable "vnet_address_space" {
  description = "CIDR range for the virtual network."
  type        = string
  default     = "10.30.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR range for the VM subnet."
  type        = string
  default     = "10.30.1.0/24"
}

variable "vm_size" {
  description = "Azure VM SKU. Standard_B1s is a low-cost burstable option where available."
  type        = string
  default     = "Standard_B1s"
}

variable "deploy_vm" {
  description = "Whether to create the workload VM and its network interface."
  type        = bool
  default     = false
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the Linux administrator; never provide a private key."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519|ecdsa) ", var.admin_ssh_public_key))
    error_message = "admin_ssh_public_key must be an OpenSSH RSA, Ed25519, or ECDSA public key."
  }
}

variable "tags" {
  description = "Tags applied to taggable workload resources."
  type        = map(string)
  default = {
    CostCenter  = "CC-0030"
    Environment = "Production"
    Owner       = "eduardbuhali@gmail.com"
  }
}

variable "nva_private_ip" {
  description = "Static private ip of the firewall/internet gateway nva that will be used on the route table"
  type        = string
  default     = "10.0.1.10"
}

variable "app_vnet_cidr" {
  description = "CIDR range for the app vnet. needed for the route table."
  type        = string
  default     = "10.20.1.0/24"
}

variable "admin_username" {
  description = "Linux administrator username."
  type        = string
  default     = "azuser"
}

variable "admin_password" {
  description = "Administrator password for the Linux VM"
  type        = string
  sensitive   = true
  default     = "AzUserP@ss01"
}