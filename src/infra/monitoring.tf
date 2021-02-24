# Adding a LogAnalytics Workspace for AKS and Container Insights
resource "azurerm_log_analytics_workspace" "deployment" {
  name                = "${lower(random_pet.deployment.id)}law"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730
}

# Application Insights
# https://www.terraform.io/docs/providers/azurerm/r/application_insights.html
resource "azurerm_application_insights" "deployment" {
  name                = "${lower(random_pet.deployment.id)}insights"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  application_type    = "web"
}

# AppInsights Instrumentation Key will be injected into a secret in K8s
output "instrumentation_key" {
  value = azurerm_application_insights.deployment.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.deployment.app_id
}

# Write Application Insights Key to Key Vault
resource "azurerm_key_vault_secret" "appinsightskey" {
  name         = "applicationInsightsKey"
  value        = azurerm_application_insights.deployment.instrumentation_key
  key_vault_id = azurerm_key_vault.deployment.id

  tags = local.default_tags
}

resource "azurerm_application_insights_api_key" "full" {
  name                    = "${lower(random_pet.deployment.id)}apikey"
  application_insights_id = azurerm_application_insights.deployment.id
  read_permissions        = ["agentconfig", "aggregate", "api", "draft", "extendqueries", "search"]
  write_permissions       = ["annotations"]
}