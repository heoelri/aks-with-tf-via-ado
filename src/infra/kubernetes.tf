# https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html
resource "azurerm_kubernetes_cluster" "deployment" {
  name                = "${lower(random_pet.deployment.id)}aks"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  dns_prefix          = "${lower(random_pet.deployment.id)}aks"
  kubernetes_version  = "1.18.14"
  sku_tier            = "Paid" # AKS Uptime SLA (free or paid)

  role_based_access_control {
    enabled = true
  }

  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_F8s_v2"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 8
    vnet_subnet_id      = azurerm_subnet.default.id
    type                = "VirtualMachineScaleSets"
    os_disk_type        = "Ephemeral"
    availability_zones  = [1,2,3]
    
    tags = local.default_tags
  }

  identity {
      type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_mode   = "transparent"
    network_policy = "azure"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.deployment.id
    }

    kube_dashboard {
      enabled = false
    }
  }

  tags = local.default_tags

}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.deployment.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.deployment.kube_config_raw
}

resource "azurerm_kubernetes_cluster_node_pool" "singletons" { 
  name                  = "singletons"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.deployment.id
  vm_size               = "Standard_D16s_v4"
  availability_zones    = [1,2,3]
  enable_auto_scaling   = true
  #enable_node_public_ip = false
  min_count             = 3
  max_count             = 10
  #node_labels           = { "workload" = "secondary" }
  node_taints           = ["dedicated=singletons:NoSchedule"]
  os_disk_size_gb       = 128 # 128
  os_disk_type          = "Ephemeral"

  tags = local.default_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "monitoring" { 
  name                  = "monitoring"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.deployment.id
  vm_size               = "Standard_D16s_v4"
  availability_zones    = [1,2,3]
  enable_auto_scaling   = true
  #enable_node_public_ip = false
  min_count             = 3
  max_count             = 10
  #node_labels           = { "workload" = "secondary" }
  node_taints           = ["role=monitoring:NoExecute"]
  os_disk_size_gb       = 128 # 128
  os_disk_type        = "Ephemeral"

  tags = local.default_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "trafficpool1" { 
  name                  = "trafficpool1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.deployment.id
  vm_size               = "Standard_D16s_v4"
  availability_zones    = [1,2,3]
  enable_auto_scaling   = true
  #enable_node_public_ip = false
  min_count             = 3
  max_count             = 100
  #node_labels           = { "workload" = "secondary" }
  #node_taints           = ["role=monitoring:NoExecute"]
  os_disk_size_gb       = 128 # 128
  os_disk_type        = "Ephemeral"

  tags = local.default_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "trafficpool2" { 
  name                  = "trafficpool2"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.deployment.id
  vm_size               = "Standard_D16s_v4"
  availability_zones    = [1,2,3]
  enable_auto_scaling   = true
  #enable_node_public_ip = false
  min_count             = 3
  max_count             = 100
  #node_labels           = { "workload" = "secondary" }
  #node_taints           = ["role=monitoring:NoExecute"]
  os_disk_size_gb       = 128 # 128
  os_disk_type        = "Ephemeral"

  tags = local.default_tags
}

# Assign AKS Cluster Managed Identity Contributor permissions 
# https://www.terraform.io/docs/providers/azurerm/r/role_assignment.html
resource "azurerm_role_assignment" "deployment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.deployment.identity.0.principal_id
}

# Assign AKS Cluster Managed Identity AcrPull
# https://www.terraform.io/docs/providers/azurerm/r/role_assignment.html
resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = data.azurerm_subscription.primary.id #/resourceGroups/${var.resource_group_name}"
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.deployment.kubelet_identity.0.object_id # identity.0.principal_id
  skip_service_principal_aad_check = true
}

# Configure Monitoring (Azure Kubernetes Service to LogAnalytics)
# https://www.terraform.io/docs/providers/azurerm/r/monitor_diagnostic_setting.html

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "aks" {
  resource_id = azurerm_kubernetes_cluster.deployment.id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aksladiagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.deployment.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.deployment.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.aks.logs

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.aks.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}