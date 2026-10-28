terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.Compute",
    "Microsoft.Network",
  ]
}

provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id                 = var.hub_subscription_id
  resource_provider_registrations = "none"
}
