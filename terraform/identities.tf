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

# One GHA identity (prod RG). Federates main + both GitHub Environments so Build
# and Deploy can push/pull the shared ACR.
resource "azurerm_user_assigned_identity" "gha" {
  count = local.owns_shared ? 1 : 0

  name                = "id-${local.name}-gha"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

data "azurerm_user_assigned_identity" "gha" {
  count = local.owns_shared ? 0 : 1

  name                = var.shared_gha_identity_name
  resource_group_name = local.shared_rg
}

resource "azurerm_federated_identity_credential" "gha_main" {
  count = local.owns_shared ? 1 : 0

  name                = "github-${var.github_app_repo}-main"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.gha[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "${local.github_oidc_sub_prefix}:ref:refs/heads/main"
}

resource "azurerm_federated_identity_credential" "gha_environment" {
  count = local.owns_shared ? 1 : 0

  name                = "github-${var.github_app_repo}-environment-prod"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.gha[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "${local.github_oidc_sub_prefix}:environment:prod"
}

resource "azurerm_federated_identity_credential" "gha_environment_dev" {
  count = local.owns_shared ? 1 : 0

  name                = "github-${var.github_app_repo}-environment-dev"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.gha[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "${local.github_oidc_sub_prefix}:environment:dev"
}

moved {
  from = azurerm_user_assigned_identity.gha
  to   = azurerm_user_assigned_identity.gha[0]
}

moved {
  from = azurerm_federated_identity_credential.gha_main
  to   = azurerm_federated_identity_credential.gha_main[0]
}

moved {
  from = azurerm_federated_identity_credential.gha_environment_prod
  to   = azurerm_federated_identity_credential.gha_environment[0]
}

moved {
  from = azurerm_federated_identity_credential.gha_environment
  to   = azurerm_federated_identity_credential.gha_environment[0]
}
