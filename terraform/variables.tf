variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Required by the azurerm 4.x provider."
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "eastus"
}

variable "prefix" {
  type        = string
  description = "Short name prefix used in resource names."
  default     = "ecs"
}

variable "environment" {
  type        = string
  description = "Environment name (used in resource names, tags, Flux path, and GitHub Environment federation). Must match the Terraform workspace (prod may use default)."
  default     = "prod"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "github_org" {
  type        = string
  description = "GitHub organization or user that owns the application repository."
  default     = "brandon-parker-code"
}

variable "github_app_repo" {
  type        = string
  description = "Application repository name (used for GitHub OIDC federated credentials)."
  default     = "email-consumer-service"
}

variable "github_org_id" {
  type        = string
  description = "Numeric GitHub owner id included in the Actions OIDC sub claim (org@id / repo@id)."
  default     = "79738728"
}

variable "github_repo_id" {
  type        = string
  description = "Numeric GitHub repository id included in the Actions OIDC sub claim."
  default     = "1271894694"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace the workload identity is federated to. Created later by Helm/Flux."
  default     = "email-consumer-service"
}

variable "k8s_service_account" {
  type        = string
  description = "Kubernetes service account the workload identity is federated to. Created later by Helm."
  default     = "email-consumer-service"
}

variable "aks_node_count" {
  type        = number
  description = "Number of nodes in the AKS system pool."
  default     = 2
}

variable "aks_vm_size" {
  type        = string
  description = "VM size for the AKS system node pool. Standard_D2s_v3 is not allowed in some eastus subscriptions; D2s_v7 is the closest replacement."
  default     = "Standard_D2s_v7"
}

variable "key_vault_admin_object_id" {
  type        = string
  description = "Optional extra Entra object ID granted Key Vault Administrator. The identity running Terraform is always granted this role. Leave empty to skip."
  default     = ""
}

variable "cluster_gitops_url" {
  type        = string
  description = "HTTPS URL of the cluster GitOps repo (Flux source)."
  default     = "https://github.com/brandon-parker-code/cluster-gitops.git"
}

variable "github_flux_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with Contents: Read on cluster-gitops and email-consumer-service-gitops. Used by the AKS Flux extension and the app GitRepository secret."
}

variable "shared_resource_group_name" {
  type        = string
  default     = ""
  description = "Resource group that owns the shared ACR, Log Analytics workspace, and GitHub Actions identity. Empty uses rg-<prefix>-prod. Required conceptually for non-prod; ignored when environment is prod."
}

variable "shared_acr_name" {
  type        = string
  default     = ""
  description = "Shared ACR name (prod output acr_name). Required when environment is not prod."
}

variable "shared_log_analytics_name" {
  type        = string
  default     = ""
  description = "Shared Log Analytics workspace name (prod output log_analytics_workspace_name). Required when environment is not prod."
}

variable "shared_gha_identity_name" {
  type        = string
  default     = ""
  description = "Shared GitHub Actions user-assigned identity name (prod output is id-<prefix>-prod-gha). Required when environment is not prod."
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Four-character suffix already used in Azure names (e.g. zr45, br6g). Set this when recovering lost state so Terraform does not generate a new suffix. Leave empty only for a true greenfield apply."
}
