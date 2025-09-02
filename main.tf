locals {

  tags = merge(
    { "deployment" = "terraform" },
    var.tags
  )
}

resource "azurerm_virtual_desktop_workspace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  friendly_name                 = var.friendly_name
  description                   = var.description
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = local.tags
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
