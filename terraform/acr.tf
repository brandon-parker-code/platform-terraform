resource "azurerm_container_registry" "this" {
  count = local.owns_shared ? 1 : 0

  name                = "acr${var.prefix}${var.environment}${local.suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.tags
}

data "azurerm_container_registry" "shared" {
  count = local.owns_shared ? 0 : 1

  name                = var.shared_acr_name
  resource_group_name = local.shared_rg
}

moved {
  from = azurerm_container_registry.this
  to   = azurerm_container_registry.this[0]
}
