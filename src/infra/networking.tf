# Azure Virtual Network Deployment
resource "azurerm_virtual_network" "deployment" {
  name                = "${random_pet.deployment.id}vnet"
  resource_group_name = azurerm_resource_group.deployment.name
  location            = azurerm_resource_group.deployment.location
  address_space       = ["10.1.0.0/16"]

  tags = local.default_tags
}

# Default Subnet Definition
resource "azurerm_subnet" "default" {
  name                                           = "default"
  resource_group_name                            = azurerm_resource_group.deployment.name
  virtual_network_name                           = azurerm_virtual_network.deployment.name
  address_prefixes                               = ["10.1.0.0/16"]
  service_endpoints                              = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.EventHub"]
  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = true
}

# Default Network Security Group Definition
resource "azurerm_network_security_group" "default-nsg" {
  name                = "${random_pet.deployment.id}nsgdefault"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
}

# Default Subnet-NSG Association
resource "azurerm_subnet_network_security_group_association" "default-nsg" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default-nsg.id
}

# Configure Monitoring (Networking to Log Analytics)
# https://www.terraform.io/docs/providers/azurerm/r/monitor_diagnostic_setting.html
resource "azurerm_monitor_diagnostic_setting" "networking" {
  name               = lower(random_pet.deployment.id)
  target_resource_id = azurerm_virtual_network.deployment.id

  #storage_account_id = azurerm_storage_account.deployment.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.deployment.id

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}