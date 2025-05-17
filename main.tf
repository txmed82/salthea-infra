terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
  }
  required_version = ">= 1.3.0"

  # Backend configuration moved to backend.tf
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {
  # Azure AD provider configuration
  tenant_id = data.azurerm_client_config.current.tenant_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "salthea_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
    hipaa       = var.hipaa_compliant ? "true" : "false"
  }
}
