provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-workspace-basic-example"
  location = "West Europe"
}

module "virtual_desktop_workspace" {
  source = "../.."

  name                = "avd-ws-basic-example"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  friendly_name       = "Basic Workspace"
  description         = "A basic AVD workspace example."

  tags = {
    "example" = "basic"
  }
}
