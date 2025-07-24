provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-ws-pe-example"
  location = "West Europe"
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-avd-ws-pe-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.wvd.microsoft.com"
  resource_group_name = azurerm_resource_group.this.name
}

module "virtual_desktop_workspace" {
  source = "../.."

  name                = "avd-ws-pe-example"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  friendly_name       = "Private Endpoint Workspace"
  public_network_access_enabled = false

  private_endpoints = {
    main = {
      subnet_id            = azurerm_subnet.this.id
      private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
      subresource_names    = ["workspace"]
    }
  }

  tags = {
    "example" = "private_endpoint"
  }
}
