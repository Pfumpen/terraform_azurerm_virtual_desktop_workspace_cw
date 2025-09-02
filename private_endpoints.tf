locals {
  workspace_endpoints_to_create = var.private_endpoint_config == null ? {} : merge(

    {
      "feed" = {
        subnet_id            = var.private_endpoint_config.subnet_id
        private_dns_zone_ids = var.private_endpoint_config.private_dns_zone_ids
        dns_group_name       = var.private_endpoint_config.private_dns_zone_group_name
      }
    },

    var.create_global_endpoint ? {
      "global" = {
        subnet_id            = var.private_endpoint_config.subnet_id
        private_dns_zone_ids = var.private_endpoint_config.private_dns_zone_ids
        dns_group_name       = var.private_endpoint_config.private_dns_zone_group_name
      }
    } : {}
  )
}

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

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
