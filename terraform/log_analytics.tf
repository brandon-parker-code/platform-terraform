resource "azurerm_log_analytics_workspace" "this" {
  count = local.owns_shared ? 1 : 0

  name                = "log-${local.name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

data "azurerm_log_analytics_workspace" "shared" {
  count = local.owns_shared ? 0 : 1

  name                = var.shared_log_analytics_name
  resource_group_name = local.shared_rg
}

# Per-cluster DCR. oms_agent deploys ama-logs but does not create this rule.
resource "azurerm_monitor_data_collection_rule" "container_insights" {
  name                = "MSCI-${azurerm_kubernetes_cluster.this.location}-${azurerm_kubernetes_cluster.this.name}"
  location            = local.law_location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "Linux"
  description         = "DCR for Azure Monitor Container Insights"
  tags                = local.tags

  destinations {
    log_analytics {
      workspace_resource_id = local.law_id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          enableContainerLogV2   = true
        }
      })
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights.id
  description             = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS cluster."
}

moved {
  from = azurerm_log_analytics_workspace.this
  to   = azurerm_log_analytics_workspace.this[0]
}
