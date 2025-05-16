# Azure Backend Configuration for Remote State
# This file is commented out by default. Uncomment when ready to use.

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "salthea-tfstate-rg"
#     storage_account_name = "saltheatfstate"
#     container_name       = "tfstate"
#     key                  = "terraform.tfstate"
#   }
# } 