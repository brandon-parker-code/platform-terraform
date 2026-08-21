resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# oms_agent deploys ama-logs but does not create this DCR. Without it, ContainerLogV2 stays empty.
# Name matches Azure's convention so portal-created rules can be imported instead of duplicated.
resource "azurerm_monitor_data_collection_rule" "container_insights" {
  name                = "MSCI-${azurerm_kubernetes_cluster.this.location}-${azurerm_kubernetes_cluster.this.name}"
  location            = azurerm_log_analytics_workspace.this.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "Linux"
  description         = "DCR for Azure Monitor Container Insights"
  tags                = local.tags

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
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
