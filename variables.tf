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

variable "private_endpoint_config" {
  description = "If configured, creates the required private endpoints for the workspace. Provide the common configuration here."
  type = object({
    subnet_id                   = string
    private_dns_zone_ids        = list(string)
    private_dns_zone_group_name = optional(string, "default")
  })
  default = null
  validation {
  condition     = !var.public_network_access_enabled ? var.private_endpoint_config != null : true
  error_message = "When public_network_access_enabled is false, a private_endpoint_config must be provided."
 }
}

variable "create_global_endpoint" {
  description = "If true and private_endpoint_config is set, a private endpoint for the 'global' sub-resource will also be created. Set this to false for any secondary workspaces in an environment that already has a global endpoint."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Diagnostic Settings Variables
#------------------------------------------------------------------------------

variable "diagnostics_level" {
  description = "Defines the desired diagnostic intent. 'all' and 'audit' are dynamically mapped to available categories. Possible values: 'none', 'all', 'audit', 'custom'."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "all", "audit", "custom"], var.diagnostics_level)
    error_message = "Valid values for diagnostics_level are 'none', 'all', 'audit', or 'custom'."
  }
}

variable "diagnostic_settings" {
  description = "A map containing the destination IDs for diagnostic settings. When diagnostics are enabled, exactly one destination must be specified."
  type = object({
    log_analytics_workspace_id     = optional(string)
    eventhub_authorization_rule_id = optional(string)
    storage_account_id             = optional(string)
  })
  default = {}

  validation {
    condition = var.diagnostics_level == "none" || (
      (try(var.diagnostic_settings.log_analytics_workspace_id, null) != null ? 1 : 0) +
      (try(var.diagnostic_settings.eventhub_authorization_rule_id, null) != null ? 1 : 0) +
      (try(var.diagnostic_settings.storage_account_id, null) != null ? 1 : 0) == 1
    )
    error_message = "When 'diagnostics_level' is not 'none', exactly one of 'log_analytics_workspace_id', 'eventhub_authorization_rule_id', or 'storage_account_id' must be specified in the 'diagnostic_settings' object."
  }
}

variable "diagnostics_custom_logs" {
  description = "A list of specific log categories to enable when diagnostics_level is 'custom'."
  type        = list(string)
  default     = []
}

variable "diagnostics_custom_metrics" {
  description = "A list of specific metric categories to enable. Use ['AllMetrics'] for all."
  type        = list(string)
  default     = ["AllMetrics"]
}
