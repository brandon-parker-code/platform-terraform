locals {
  name        = "${var.prefix}-${var.environment}"
  owns_shared = var.environment == "prod"
  shared_rg   = coalesce(var.shared_resource_group_name, "rg-${var.prefix}-prod")

  github_oidc_sub_prefix = "repo:${var.github_org}@${var.github_org_id}/${var.github_app_repo}@${var.github_repo_id}"

  acr_id           = one(concat(azurerm_container_registry.this[*].id, data.azurerm_container_registry.shared[*].id))
  acr_name         = one(concat(azurerm_container_registry.this[*].name, data.azurerm_container_registry.shared[*].name))
  acr_login_server = one(concat(azurerm_container_registry.this[*].login_server, data.azurerm_container_registry.shared[*].login_server))

  law_id       = one(concat(azurerm_log_analytics_workspace.this[*].id, data.azurerm_log_analytics_workspace.shared[*].id))
  law_name     = one(concat(azurerm_log_analytics_workspace.this[*].name, data.azurerm_log_analytics_workspace.shared[*].name))
  law_location = one(concat(azurerm_log_analytics_workspace.this[*].location, data.azurerm_log_analytics_workspace.shared[*].location))

  gha_client_id    = one(concat(azurerm_user_assigned_identity.gha[*].client_id, data.azurerm_user_assigned_identity.gha[*].client_id))
  gha_principal_id = one(concat(azurerm_user_assigned_identity.gha[*].principal_id, data.azurerm_user_assigned_identity.gha[*].principal_id))

  # Pin after a lost Cloud Shell state so apply/import does not rename ACR/KV.
  suffix = var.name_suffix != "" ? var.name_suffix : random_string.suffix.result

  tags = {
    project     = "email-consumer-service"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags

  lifecycle {
    precondition {
      condition = (
        var.environment == "prod" && contains(["default", "prod"], terraform.workspace)
        ) || (
        var.environment != "prod" && terraform.workspace == var.environment
      )
      error_message = "Workspace \"${terraform.workspace}\" does not match environment \"${var.environment}\". Prod may use workspace default or prod; other environments must use a workspace of the same name. Applying the wrong var-file in the prod workspace will replace prod."
    }

    precondition {
      condition = local.owns_shared || (
        var.shared_acr_name != "" &&
        var.shared_log_analytics_name != "" &&
        var.shared_gha_identity_name != ""
      )
      error_message = "Non-prod environments must set shared_acr_name, shared_log_analytics_name, and shared_gha_identity_name (prod Terraform outputs)."
    }
  }
}
