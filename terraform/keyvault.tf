resource "azurerm_key_vault" "this" {
  name                          = "kv-${local.name}-${local.suffix}"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  tags                          = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  timeouts {
    create = "15m"
    read   = "10m"
    update = "10m"
  }
}

data "azurerm_client_config" "current" {}
