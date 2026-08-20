resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${local.name}-workload"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "workload" {
  name                = "aks-${local.name}-workload"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"
}

resource "azurerm_user_assigned_identity" "gha" {
  name                = "id-${local.name}-gha"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gha_main" {
  name                = "github-${var.github_app_repo}-main"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.gha.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "${local.github_oidc_sub_prefix}:ref:refs/heads/main"
}

resource "azurerm_federated_identity_credential" "gha_environment_prod" {
  name                = "github-${var.github_app_repo}-environment-prod"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.gha.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "${local.github_oidc_sub_prefix}:environment:prod"
}
