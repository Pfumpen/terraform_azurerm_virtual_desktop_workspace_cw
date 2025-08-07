provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

#------------------------------------------------------------------------------
# Common Resources
#------------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-ws-complete-example"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-avd-ws-complete"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
}

#------------------------------------------------------------------------------
# AVD Application Group Resources
#------------------------------------------------------------------------------

resource "azurerm_virtual_desktop_host_pool" "this" {
  name                = "hp-avd-ws-complete"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
}

resource "azurerm_virtual_desktop_application_group" "this" {
  name                = "ag-avd-ws-complete"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "RemoteApp"
  host_pool_id        = azurerm_virtual_desktop_host_pool.this.id
}

#------------------------------------------------------------------------------
# Networking Resources for Private Endpoint
#------------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = "vnet-avd-ws-complete-example"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                              = "snet-pep"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = ["10.1.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.wvd.microsoft.com"
  resource_group_name = azurerm_resource_group.this.name
}

#------------------------------------------------------------------------------
# Module Call
#------------------------------------------------------------------------------

module "virtual_desktop_workspace" {
  source = "../.."

  name                          = "avd-ws-complete-example"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  friendly_name                 = "Complete Workspace"
  description                   = "A complete AVD workspace example."
  public_network_access_enabled = false

  application_group_associations = {
    default_ag = azurerm_virtual_desktop_application_group.this.id
  }

  role_assignments = {
    "DesktopVirtualizationUser" = {
      role_definition_id_or_name = "Desktop Virtualization User"
      principal_id               = "00000000-0000-0000-0000-000000000000" # Replace with a valid Principal ID
    }
  }

  private_endpoint_config = {
    subnet_id            = azurerm_subnet.this.id
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  diagnostics_level = "all"
  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  tags = {
    "example"   = "complete"
    "terraform" = "true"
  }
}
