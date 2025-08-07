provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

#------------------------------------------------------------------------------
# Common Resources
#------------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-ws-multi-example"
  location = "westeurope"
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-avd-ws-multi-example"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                              = "snet-pep"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = ["10.2.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.wvd.microsoft.com"
  resource_group_name = azurerm_resource_group.this.name
}

#------------------------------------------------------------------------------
# Module Call: Primary Workspace
#------------------------------------------------------------------------------

module "primary_workspace" {
  source = "../.."

  name                          = "avd-ws-primary-example"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  friendly_name                 = "Primary Workspace"
  public_network_access_enabled = false
  create_global_endpoint        = true // Default, but explicit for clarity

  private_endpoint_config = {
    subnet_id            = azurerm_subnet.this.id
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  tags = {
    "example" = "multi-workspace-primary"
  }
}

#------------------------------------------------------------------------------
# Module Call: Secondary Workspace
#------------------------------------------------------------------------------

module "secondary_workspace" {
  source = "../.."

  name                          = "avd-ws-secondary-example"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  friendly_name                 = "Secondary Workspace"
  public_network_access_enabled = false
  create_global_endpoint        = false // Key for secondary workspace

  private_endpoint_config = {
    subnet_id            = azurerm_subnet.this.id
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  tags = {
    "example" = "multi-workspace-secondary"
  }
}
