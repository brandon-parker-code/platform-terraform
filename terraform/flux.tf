resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "flux"
  cluster_id     = azurerm_kubernetes_cluster.this.id
  extension_type = "microsoft.flux"
}

resource "azurerm_kubernetes_flux_configuration" "cluster" {
  name       = "cluster-gitops"
  cluster_id = azurerm_kubernetes_cluster.this.id
  namespace  = "flux-system"
  scope      = "cluster"

  git_repository {
    url                      = var.cluster_gitops_url
    reference_type           = "branch"
    reference_value          = "main"
    https_user               = var.github_org
    https_key_base64         = base64encode(var.github_flux_token)
    sync_interval_in_seconds = 60
  }

  kustomizations {
    name                       = "cluster"
    path                       = "./clusters/prod"
    sync_interval_in_seconds   = 60
    retry_interval_in_seconds  = 60
    garbage_collection_enabled = true
  }

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}

resource "kubernetes_secret_v1" "email_consumer_git" {
  metadata {
    name      = "email-consumer-service"
    namespace = "flux-system"
  }

  data = {
    username = var.github_org
    password = var.github_flux_token
  }

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}
