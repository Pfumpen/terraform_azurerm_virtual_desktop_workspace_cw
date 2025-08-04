#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------

locals {
  # Merge user-provided tags with module-default tags
  tags = merge(
    {
      "module" = "terraform-azurerm-virtual-desktop-workspace"
    },
    var.tags
  )
}

#------------------------------------------------------------------------------
# Core Resource: Virtual Desktop Workspace
#------------------------------------------------------------------------------

resource "azurerm_virtual_desktop_workspace" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  friendly_name                 = var.friendly_name
  description                   = var.description
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = local.tags

  lifecycle {
    # Precondition to ensure that if public network access is disabled,
    # at least one private endpoint is defined to maintain connectivity.
    precondition {
      condition     = var.public_network_access_enabled || length(var.private_endpoints) > 0
      error_message = "Disabling public network access requires at least one private endpoint to be configured."
    }
  }
}
