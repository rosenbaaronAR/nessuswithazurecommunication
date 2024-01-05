
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.57.0"

    }
    azuread = {
      source = "hashicorp/azuread"
    }
    azapi = {
      source = "azure/azapi"
    }

  }

}

provider "azurerm" {
  features {
  }
}

provider "azapi" {

}
