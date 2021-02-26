# Load and configure the helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.deployment.kube_config.0.host
    username               = azurerm_kubernetes_cluster.deployment.kube_config.0.username
    password               = azurerm_kubernetes_cluster.deployment.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.deployment.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.deployment.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.deployment.kube_config.0.cluster_ca_certificate)
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

    # Load additional config from src/config/nginx-ingress/values.yaml
    values = [
        templatefile("src/config/nginx-ingress/values.yaml", {})
    ]

    set {
        name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
        value = azurerm_resource_group.deployment.name
    }
    set {
        name = "controller.service.loadBalancerIP"
        value = azurerm_public_ip.ingress.ip_address
    }

}