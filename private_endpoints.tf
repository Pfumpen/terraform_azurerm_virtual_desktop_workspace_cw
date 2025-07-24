#------------------------------------------------------------------------------
# Resource: Private Endpoints
#------------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = "pep-${var.name}-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = each.value.subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-${var.name}-${each.key}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_virtual_desktop_workspace.this.id
    subresource_names              = each.value.subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = length(try(each.value.private_dns_zone_ids, [])) > 0 ? [1] : []
    content {
      name                 = try(each.value.private_dns_zone_group_name, "default")
      private_dns_zone_ids = try(each.value.private_dns_zone_ids, [])
    }
  }

  lifecycle {
    # Precondition to ensure that the subresource name is valid for the workspace.
    precondition {
      condition     = alltrue([for sr in each.value.subresource_names : contains(["workspace"], sr)])
      error_message = "The subresource_names for a Virtual Desktop Workspace private endpoint must contain 'workspace'."
    }
  }
}
