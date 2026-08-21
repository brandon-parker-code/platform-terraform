resource "azurerm_role_assignment" "acr_pull_kubelet" {
  scope                = local.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "acr_push_gha" {
  count = local.owns_shared ? 1 : 0

  scope                = local.acr_id
  role_definition_name = "AcrPush"
  principal_id         = local.gha_principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_workload" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "kv_admin_applier" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_admin" {
  count = var.key_vault_admin_object_id == "" || var.key_vault_admin_object_id == data.azurerm_client_config.current.object_id ? 0 : 1

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.key_vault_admin_object_id
}

moved {
  from = azurerm_role_assignment.acr_push_gha
  to   = azurerm_role_assignment.acr_push_gha[0]
}
