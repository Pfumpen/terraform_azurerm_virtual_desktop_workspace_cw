#------------------------------------------------------------------------------
# Resource: Virtual Desktop Workspace Application Group Association
#------------------------------------------------------------------------------

resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  for_each = var.application_group_associations

  workspace_id          = azurerm_virtual_desktop_workspace.this.id
  application_group_id = each.value
}
