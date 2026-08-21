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
  value = azurerm_container_registry.this.name
}

output "ACR_LOGIN_SERVER" {
  value       = azurerm_container_registry.this.login_server
  description = "GitHub Actions variable ACR_LOGIN_SERVER."
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

output "AZURE_CLIENT_ID" {
  value       = azurerm_user_assigned_identity.gha.client_id
  description = "GitHub Actions secret AZURE_CLIENT_ID (GitHub Actions managed identity)."
}

output "k8s_namespace" {
  value = var.k8s_namespace
}

output "k8s_service_account" {
  value = var.k8s_service_account
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.this.name
  description = "Azure Monitor / Container Insights workspace. Query ContainerLogV2 for pod stdout."
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "container_insights_dcr_name" {
  value       = azurerm_monitor_data_collection_rule.container_insights.name
  description = "Container Insights data collection rule. Query ContainerLogV2 in the workspace above."
}
