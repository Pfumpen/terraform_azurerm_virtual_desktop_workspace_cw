# Terraform Module: Azure Virtual Desktop Workspace

This Terraform module provides a standardized and flexible way to deploy an Azure Virtual Desktop Workspace. It simplifies the creation of the core workspace and integrates related resources like application group associations, role-based access control (RBAC), private endpoints, and diagnostic settings, adhering to Azure best practices.

## Features

- **Core Workspace Management**: Deploys a Virtual Desktop Workspace with configurable naming, location, and descriptions.
- **Network Security**: Supports both public and private network access. Enforces private-only access by creating Private Endpoints when public access is disabled.
- **Application Group Integration**: Easily associates existing Virtual Desktop Application Groups with the workspace.
- **Integrated RBAC**: Manages role assignments at the workspace scope for granular permission control.
- **Private Connectivity**: Simplifies the creation of Private Endpoints for secure, private access to the workspace.
- **Comprehensive Monitoring**: Configures diagnostic settings to stream logs and metrics to various destinations like Log Analytics, Event Hubs, or a Storage Account.
- **Tagging**: Applies a consistent set of tags to all created resources for better organization and cost management.

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.11.0 |
| azurerm | >= 4.31.0 |

## External Dependencies

- **Resource Group**: An existing Azure Resource Group must be provided via the `resource_group_name` variable.
- **Virtual Network & Subnet**: Required for Private Endpoint creation, provided via the `subnet_id` attribute within the `private_endpoints` variable.
- **Application Groups**: Existing Application Group resource IDs are required for association, provided via the `application_group_associations` variable.
- **Diagnostic Destinations**: Existing Log Analytics Workspace, Event Hub, or Storage Account resource IDs are required for diagnostics, provided via the `diagnostic_settings` variable.

## Resources Created

| Type | Name |
|---|---|
| `azurerm_virtual_desktop_workspace` | `this` |
| `azurerm_virtual_desktop_workspace_application_group_association` | `this` (for_each) |
| `azurerm_role_assignment` | `this` (for_each) |
| `azurerm_private_endpoint` | `this` (for_each) |
| `azurerm_monitor_diagnostic_setting` | `this` (count) |
| `azurerm_monitor_diagnostic_categories` | `this` (count) |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| `name` | Specifies the name of the Virtual Desktop Workspace. Changing this forces a new resource to be created. | `string` | n/a | yes |
| `resource_group_name` | The name of the existing Resource Group where the Virtual Desktop Workspace will be deployed. | `string` | n/a | yes |
| `location` | The Azure region where the Virtual Desktop Workspace and all associated resources will be created. | `string` | n/a | yes |
| `friendly_name` | A friendly name for the Virtual Desktop Workspace, visible to users in the client. | `string` | `null` | no |
| `description` | A description for the Virtual Desktop Workspace. | `string` | `null` | no |
| `public_network_access_enabled` | Determines whether public network access is allowed for this workspace. Set to false to enforce access only via Private Endpoints. | `bool` | `true` | no |
| `tags` | A map of tags to assign to all created resources. These tags will be merged with the module's default tags. | `map(string)` | `{}` | no |
| `application_group_associations` | A map where the key is a logical name and the value is the Resource ID of a Virtual Desktop Application Group to associate with the workspace. | `map(string)` | `{}` | no |
| `role_assignments` | A map of role assignments to create on the Virtual Desktop Workspace scope. See structure below. | `map(object)` | `{}` | no |
| `private_endpoints` | A map of Private Endpoints to create for the Virtual Desktop Workspace. See structure below. | `map(object)` | `{}` | no |
| `diagnostics_level` | Defines the desired diagnostic intent. Possible values: 'none', 'all', 'audit', 'custom'. | `string` | `"none"` | no |
| `diagnostic_settings` | A map containing the destination IDs for diagnostic settings. See structure below. | `object` | `{}` | no |
| `diagnostics_custom_logs` | A list of specific log categories to enable when diagnostics_level is 'custom'. | `list(string)` | `[]` | no |
| `diagnostics_custom_metrics` | A list of specific metric categories to enable. Use `['AllMetrics']` for all. | `list(string)` | `["AllMetrics"]` | no |

### `role_assignments` variable structure

A map of objects to define role assignments on the workspace.

- `role_definition_id_or_name` (string, required): The built-in role name or full resource ID of the role definition.
- `principal_id` (string, required): The object ID of the principal (user, group, or service principal).
- `principal_type` (string, optional): The type of principal. Defaults to `ServicePrincipal`. Allowed values: `User`, `Group`, `ServicePrincipal`.

Type: `map(object({ role_definition_id_or_name = string, principal_id = string, principal_type = optional(string, "ServicePrincipal") }))`

Example:
```hcl
role_assignments = {
  "avd-admins" = {
    role_definition_id_or_name = "Desktop Virtualization User"
    principal_id               = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    principal_type             = "Group"
  }
}
```

### `private_endpoints` variable structure

A map of objects to define Private Endpoints for the workspace.

- `subnet_id` (string, required): The resource ID of the subnet to deploy the private endpoint into.
- `subresource_names` (list(string), required): A list of sub-resources to connect to. For a workspace, this must be `["workspace"]`.
- `private_dns_zone_group_name` (string, optional): The name of the Private DNS Zone Group to create. Defaults to `default`.
- `private_dns_zone_ids` (list(string), optional): A list of Private DNS Zone resource IDs to associate with the endpoint.

Type: `map(object({ subnet_id = string, private_dns_zone_group_name = optional(string, "default"), private_dns_zone_ids = optional(list(string), []), subresource_names = list(string) }))`

Example:
```hcl
private_endpoints = {
  "main-endpoint" = {
    subnet_id         = "/subscriptions/sub-id/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-core/subnets/private-endpoints"
    subresource_names = ["workspace"]
    private_dns_zone_ids = [
      "/subscriptions/sub-id/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.wvd.microsoft.com"
    ]
  }
}
```

### `diagnostic_settings` variable structure

An object to define the destination for diagnostic logs and metrics.

- `log_analytics_workspace_id` (string, optional): Resource ID of the Log Analytics Workspace.
- `eventhub_authorization_rule_id` (string, optional): Resource ID of the Event Hub authorization rule.
- `storage_account_id` (string, optional): Resource ID of the Storage Account.

Type: `object({ log_analytics_workspace_id = optional(string), eventhub_authorization_rule_id = optional(string), storage_account_id = optional(string) })`

Example:
```hcl
diagnostic_settings = {
  log_analytics_workspace_id = "/subscriptions/sub-id/resourceGroups/rg-monitor/providers/Microsoft.OperationalInsights/workspaces/log-analytics-workspace"
}
```

## Outputs

| Name | Description | Sensitive |
|---|---|:---:|
| `id` | The resource ID of the Virtual Desktop Workspace. | false |
| `private_endpoints` | A map of created Private Endpoint details, including their resource IDs and FQDNs. | true |
| `role_assignment_ids` | A map of created role assignment resource IDs, keyed by the input map key. | false |

## Usage Examples

### Basic Workspace

This example deploys a simple Virtual Desktop Workspace with default settings. See the `examples/basic` directory for the full code.

```hcl
module "virtual_desktop_workspace_basic" {
  source = "<path_to_module>/examples/basic"

  name                = "avd-ws-basic-example"
  resource_group_name = "rg-avd-example"
  location            = "West Europe"
  friendly_name       = "My Basic Workspace"
  description         = "A basic AVD workspace deployment."
}
```

### Complete Workspace with Private Endpoint and RBAC

This example demonstrates a more complex setup, including a private endpoint, role assignments, and application group associations. See the `examples/complete` directory for the full code.

```hcl
module "virtual_desktop_workspace_complete" {
  source = "<path_to_module>/examples/complete"

  name                          = "avd-ws-complete-example"
  resource_group_name           = "rg-avd-example"
  location                      = "West Europe"
  friendly_name                 = "My Secure Workspace"
  description                   = "A comprehensive AVD workspace with private networking."
  public_network_access_enabled = false

  application_group_associations = {
    "default-apps" = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-avd-example/providers/Microsoft.DesktopVirtualization/applicationGroups/avd-apps-default"
  }

  role_assignments = {
    "desktop-virtualization-user" = {
      role_definition_id_or_name = "Virtual Machine User Login"
      principal_id               = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  }

  private_endpoints = {
    "workspace-endpoint" = {
      subnet_id           = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-network-example/providers/Microsoft.Network/virtualNetworks/vnet-main/subnets/private-endpoints"
      subresource_names   = ["workspace"]
      private_dns_zone_ids = ["/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-dns-example/providers/Microsoft.Network/privateDnsZones/privatelink.wvd.microsoft.com"]
    }
  }

  tags = {
    "environment" = "production"
    "cost-center" = "it-avd"
  }
}
