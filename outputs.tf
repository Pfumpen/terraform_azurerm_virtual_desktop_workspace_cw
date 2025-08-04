#------------------------------------------------------------------------------
# Output: Virtual Desktop Workspace
#------------------------------------------------------------------------------

output "id" {
  description = "The resource ID of the Virtual Desktop Workspace."
  value       = azurerm_virtual_desktop_workspace.this.id
}

#------------------------------------------------------------------------------
# Output: Private Endpoints
#------------------------------------------------------------------------------

output "private_endpoints" {
  description = "A map of created Private Endpoint details, including their resource IDs and FQDNs."
  value = { for k, v in azurerm_private_endpoint.this : k => {
    id   = v.id
    fqdn = try(v.private_service_connection[0].private_ip_address, null)
  } }
  sensitive = true
}

#------------------------------------------------------------------------------
# Output: Role Assignments
#------------------------------------------------------------------------------

output "role_assignment_ids" {
  description = "A map of created role assignment resource IDs, keyed by the input map key."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}
