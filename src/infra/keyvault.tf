# Create an Azure Key Vault
# https://www.terraform.io/docs/providers/azurerm/r/key_vault.html
resource "azurerm_key_vault" "deployment" {
  name                        = "${lower(random_pet.deployment.id)}kv"
  location                    = azurerm_resource_group.deployment.location
  resource_group_name         = azurerm_resource_group.deployment.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      azurerm_subnet.default.id
    ]

  }

  tags = local.default_tags
}

# Add Pipeline Service Principal to Azure KeyVault Access Policy
# https://www.terraform.io/docs/providers/azurerm/r/key_vault_access_policy.html
resource "azurerm_key_vault_access_policy" "kv-self-access" {
  key_vault_id = azurerm_key_vault.deployment.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get",
  ]

  certificate_permissions = [
    "get",
  ]

  secret_permissions = [
    "get", "set", "Delete", "list"
  ]

  storage_permissions = [
    "get",
  ]
}

# Add AKS Managed Identity to Key Vault Access Policy
# https://www.terraform.io/docs/providers/azurerm/r/key_vault_access_policy.html
resource "azurerm_key_vault_access_policy" "kv-aks-access" {
  key_vault_id = azurerm_key_vault.deployment.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_kubernetes_cluster.deployment.identity.0.principal_id

  key_permissions = [
    "get",
  ]

  certificate_permissions = [
    "get",
  ]

  secret_permissions = [
    "get",
  ]

  storage_permissions = [
    "get",
  ]
}


# Configure Monitoring (Azure KeyVault to LogAnalytics)
# https://www.terraform.io/docs/providers/azurerm/r/monitor_diagnostic_setting.html
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name               = lower(random_pet.deployment.id)
  target_resource_id = azurerm_key_vault.deployment.id

  #storage_account_id = azurerm_storage_account.deployment.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.deployment.id

  log {
    category = "AuditEvent"
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