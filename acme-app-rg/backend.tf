terraform {
  backend "azurerm" {
    resource_group_name  = "bootstrapLandingZoneTF"
    storage_account_name = "ekbtechforgealzsa"
    container_name       = "platform-alz-tf-files"
    key                  = "ubuntuNva-application.terraform.tfstate"
    use_azuread_auth     = true
  }
}