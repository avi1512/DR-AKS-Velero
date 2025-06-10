terraform {
  required_version = ">= 1.3.5"
  required_providers {
    azurerm = "4.27.0"
  }
}
provider "azurerm" {
  features {}
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id 
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
}