output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "acr_name" {
  value = local.acr_name
}

output "ACR_LOGIN_SERVER" {
  value       = local.acr_login_server
  description = "Shared ACR. Same value for every GitHub Environment."
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "AZURE_TENANT_ID" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "GitHub Actions secret AZURE_TENANT_ID."
}

output "AZURE_SUBSCRIPTION_ID" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "GitHub Actions secret AZURE_SUBSCRIPTION_ID."
}

output "workload_identity_client_id" {
  value       = azurerm_user_assigned_identity.workload.client_id
  description = "Set as azure.workload.identity/client-id on the Kubernetes service account."
}

output "workload_identity_name" {
  value = azurerm_user_assigned_identity.workload.name
}

output "gha_identity_name" {
  value       = one(concat(azurerm_user_assigned_identity.gha[*].name, data.azurerm_user_assigned_identity.gha[*].name))
  description = "Shared GitHub Actions identity name. Pass as shared_gha_identity_name when applying a non-prod workspace."
}

output "AZURE_CLIENT_ID" {
  value       = local.gha_client_id
  description = "Shared GitHub Actions identity. Same value for GitHub Environments prod and dev."
}

output "k8s_namespace" {
  value = var.k8s_namespace
}

output "k8s_service_account" {
  value = var.k8s_service_account
}

output "log_analytics_workspace_name" {
  value       = local.law_name
  description = "Shared Azure Monitor workspace. Query ContainerLogV2; filter by cluster or namespace."
}

output "log_analytics_workspace_id" {
  value = local.law_id
}

output "container_insights_dcr_name" {
  value       = azurerm_monitor_data_collection_rule.container_insights.name
  description = "Container Insights data collection rule. Query ContainerLogV2 in the workspace above."
}
