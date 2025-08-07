#------------------------------------------------------------------------------
# Private Endpoint Logic
#------------------------------------------------------------------------------

locals {
  # This logic conditionally builds the map of endpoints to create.
  # It uses the merge function to combine the mandatory 'feed' endpoint
  # with the optional 'global' endpoint.
  workspace_endpoints_to_create = var.private_endpoint_config == null ? {} : merge(

    # 1. The 'feed' endpoint is ALWAYS created if private_endpoint_config is provided.
    {
      "feed" = {
        subnet_id            = var.private_endpoint_config.subnet_id
        private_dns_zone_ids = var.private_endpoint_config.private_dns_zone_ids
        dns_group_name       = var.private_endpoint_config.private_dns_zone_group_name
      }
    },

    # 2. The 'global' endpoint is ONLY merged into the map if var.create_global_endpoint is true.
    var.create_global_endpoint ? {
      "global" = {
        subnet_id            = var.private_endpoint_config.subnet_id
        private_dns_zone_ids = var.private_endpoint_config.private_dns_zone_ids
        dns_group_name       = var.private_endpoint_config.private_dns_zone_group_name
      }
    } : {}
  )
}

#------------------------------------------------------------------------------
# Private Endpoint Resource
#------------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  for_each = local.workspace_endpoints_to_create

  name                = "pep-${var.name}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "psc-${var.name}-${each.key}"
    private_connection_resource_id = azurerm_virtual_desktop_workspace.this.id
    is_manual_connection           = false
    subresource_names              = [each.key]
  }

  private_dns_zone_group {
    name                 = each.value.dns_group_name
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }

  tags = var.tags
}
