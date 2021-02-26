# Load and configure the helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.deployment.kube_config.0.host
    username               = azurerm_kubernetes_cluster.deployment.kube_config.0.username
    password               = azurerm_kubernetes_cluster.deployment.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.deployment.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.deployment.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.deployment.kube_config.0.cluster_ca_certificate)
    load_config_file       = false
  }
}

# Deploy NGINX Ingress Controller (with autoscale)
resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.23.0"
  timeout    = 300 # timeout in seconds
  wait       = true 

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "controller.autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }

  set {
    name  = "controller.autoscaling.maxReplicas"
    value = "10"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "500Mi"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1000m"
  }
}