#------------------------------------------------------------------------------
# General Variables
#------------------------------------------------------------------------------

variable "name" {
  type        = string
  description = "Specifies the name of the Virtual Desktop Workspace. Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.name))
    error_message = "The workspace name must be between 3 and 63 characters long, start and end with a letter or number, and can only contain letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the existing Resource Group where the Virtual Desktop Workspace will be deployed."

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,90}$", var.resource_group_name))
    error_message = "The resource group name must be between 1 and 90 characters long and can contain alphanumerics, underscores, periods, and hyphens."
  }
}

variable "location" {
  type        = string
  description = "The Azure region where the Virtual Desktop Workspace and all associated resources will be created."
}

variable "friendly_name" {
  type        = string
  description = "A friendly name for the Virtual Desktop Workspace, visible to users in the client."
  default     = null
}

variable "description" {
  type        = string
  description = "A description for the Virtual Desktop Workspace."
  default     = null
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Determines whether public network access is allowed for this workspace. Set to false to enforce access only via Private Endpoints."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to all created resources. These tags will be merged with the module's default tags."
  default     = {}
}

#------------------------------------------------------------------------------
# Association Variables
#------------------------------------------------------------------------------

variable "application_group_associations" {
  type        = map(string)
  description = "A map where the key is a logical name and the value is the Resource ID of a Virtual Desktop Application Group to associate with the workspace."
  default     = {}

  validation {
    condition = alltrue([
      for id in values(var.application_group_associations) : can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.DesktopVirtualization/applicationGroups/.+$", id))
    ])
    error_message = "All values in application_group_associations must be valid Azure Resource IDs for Virtual Desktop Application Groups."
  }
}

#------------------------------------------------------------------------------
# RBAC Variables
#------------------------------------------------------------------------------

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name = string
    principal_id               = string
    principal_type             = optional(string, "ServicePrincipal")
  }))
  description = "A map of role assignments to create on the Virtual Desktop Workspace scope. The key is a descriptive name for the assignment."
  default     = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) : assignment.role_definition_id_or_name != null && length(assignment.role_definition_id_or_name) > 0
    ])
    error_message = "The 'role_definition_id_or_name' attribute for each role assignment cannot be null or empty."
  }

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) : can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", assignment.principal_id))
    ])
    error_message = "The 'principal_id' for each role assignment must be a valid GUID."
  }

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) : contains(["User", "Group", "ServicePrincipal"], assignment.principal_type)
    ])
    error_message = "The 'principal_type' for each role assignment must be one of 'User', 'Group', or 'ServicePrincipal'."
  }
}

#------------------------------------------------------------------------------
# Private Endpoint Variables
#------------------------------------------------------------------------------

variable "private_endpoints" {
  type = map(object({
    subnet_id                  = string
    private_dns_zone_group_name = optional(string, "default")
    private_dns_zone_ids       = optional(list(string), [])
    subresource_names          = list(string)
  }))
  description = "A map of Private Endpoints to create for the Virtual Desktop Workspace. The key is a descriptive name for the endpoint."
  default     = {}

  validation {
    condition = alltrue([
      for pe in values(var.private_endpoints) : can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", pe.subnet_id))
    ])
    error_message = "The 'subnet_id' for each private endpoint must be a valid Azure Resource ID for a subnet."
  }

  validation {
    condition = alltrue([
      for pe in values(var.private_endpoints) : alltrue([
        for id in pe.private_dns_zone_ids : can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/privateDnsZones/.+$", id))
      ])
    ])
    error_message = "All 'private_dns_zone_ids' for each private endpoint must be valid Azure Resource IDs for Private DNS Zones."
  }

  validation {
    condition = alltrue([
      for pe in values(var.private_endpoints) : length(pe.subresource_names) > 0
    ])
    error_message = "The 'subresource_names' list for each private endpoint cannot be empty."
  }
}

#------------------------------------------------------------------------------
# Diagnostic Settings Variables
#------------------------------------------------------------------------------

variable "diagnostic_settings" {
  type = object({
    enabled                      = optional(bool, false)
    log_analytics_workspace_id   = optional(string)
    eventhub_authorization_rule_id = optional(string)
    storage_account_id           = optional(string)
    log_categories               = optional(list(string), [])
    metric_categories            = optional(list(string), ["AllMetrics"])
  })
  description = "A configuration object for diagnostic settings on the Virtual Desktop Workspace."
  default     = {}

  validation {
    condition     = !var.diagnostic_settings.enabled || (var.diagnostic_settings.log_analytics_workspace_id != null || var.diagnostic_settings.eventhub_authorization_rule_id != null || var.diagnostic_settings.storage_account_id != null)
    error_message = "When diagnostic_settings are enabled, at least one destination (Log Analytics, Event Hub, or Storage Account) must be specified."
  }
}
