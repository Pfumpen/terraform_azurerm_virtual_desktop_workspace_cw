#------------------------------------------------------------------------------
# Resource: Role Assignments
#------------------------------------------------------------------------------

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_virtual_desktop_workspace.this.id
  role_definition_name = !can(regex("^/subscriptions/.+", each.value.role_definition_id_or_name)) ? each.value.role_definition_id_or_name : null
  role_definition_id   = can(regex("^/subscriptions/.+", each.value.role_definition_id_or_name)) ? each.value.role_definition_id_or_name : null
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
}
