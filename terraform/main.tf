locals {
  name = "${var.prefix}-${var.environment}"

  github_oidc_sub_prefix = "repo:${var.github_org}@${var.github_org_id}/${var.github_app_repo}@${var.github_repo_id}"

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
}
