// Hard code the credential for the Terraform
provider "azurerm" {
    subscription_id = "xxxx"
    client_id       = "xxxx"
    client_secret   = "xxxx"
    tenant_id       = "xxxx"
}


// Get the diagnostic_name from diagnostic_resource_id
locals{
	count = "${length(split("/","${var.diagnostic_resource_id}"))-1}"
    diagnostic_name = "${split("/","${var.diagnostic_resource_id}")["${local.count}"]}"
}

resource "azurerm_dashboard" "k8s-cluster-dashboard" {
    name                       = "${var.dashboard_name}"
    resource_group_name        = "${var.rg_name}"
    location                   = "${var.rg_location}" 
    tags = {
        source = "terraform"
    }
    dashboard_properties       = <<DASH
{
    "lenses": {
      "0": {
        "order": 0,
        "parts": {
          "0": {
            "position": {
              "x": 0,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "ComponentId",
                  "value": {
                    "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "ResourceGroup": "${var.input_rg_name}",
                    "Name": "${local.diagnostic_name}",
					"ResourceId": "${var.diagnostic_resource_id}"
                  }
                },
                {
                  "name": "Query",
                  "value": "// AKSNodeCPU\r\nlet endDateTime = now();\r\nlet startDateTime = ago(6h);\r\nlet trendBinSize = 1m;\r\nlet capacityCounterName = 'cpuCapacityNanoCores';\r\nlet usageCounterName = 'cpuUsageNanoCores';\r\nKubeNodeInventory\r\n| where ClusterName startswith 'liq' \r\n| where TimeGenerated < endDateTime\r\n| where TimeGenerated >= startDateTime\r\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\r\n| distinct ClusterName, Computer\r\n| join kind= inner (\r\n  Perf\r\n  | where TimeGenerated < endDateTime\r\n  | where TimeGenerated >= startDateTime\r\n  | where ObjectName == 'K8SNode'\r\n  | where CounterName == capacityCounterName\r\n  | summarize LimitValue = max(CounterValue) by Computer, CounterName, bin(TimeGenerated, trendBinSize)\r\n  | project Computer, CapacityStartTime = TimeGenerated, CapacityEndTime = TimeGenerated + trendBinSize, LimitValue\r\n) on Computer\r\n| join kind=inner (\r\n  Perf\r\n  | where TimeGenerated < endDateTime + trendBinSize\r\n  | where TimeGenerated >= startDateTime - trendBinSize\r\n  | where ObjectName == 'K8SNode'\r\n  | where CounterName == usageCounterName\r\n  | project Computer, UsageValue = CounterValue, TimeGenerated\r\n) on Computer\r\n| where TimeGenerated >= CapacityStartTime and TimeGenerated < CapacityEndTime\r\n| project ClusterName, Computer, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\r\n| summarize CpuUsagePercent = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ClusterName\r\n//| extend UTCtoPST = TimeGenerated - 7h  // convert UTC to PST\r\n//| project-away TimeGenerated            // remove the x-axis entry for UTC\r\n| render timechart\n"
                },
                {
                  "name": "Dimensions",
                  "value": {
                    "xAxis": {
                      "name": "TimeGenerated",
                      "type": "datetime"
                    },
                    "yAxis": [
                      {
                        "name": "CpuUsagePercent",
                        "type": "real"
                      }
                    ],
                    "splitBy": [
                      {
                        "name": "ClusterName",
                        "type": "string"
                      }
                    ],
                    "aggregation": "Average"
                  }
                },
                {
                  "name": "Version",
                  "value": "1.0"
                },
				{
                  "name": "PartId",
                  "value": "xxxx"
                },
                {
                  "name": "PartTitle",
                  "value": "Analytics"
                },
                {
                  "name": "PartSubTitle",
                  "value": "${local.diagnostic_name}"
                },
                {
                  "name": "resourceTypeMode",
                  "value": "workspace"
                },
                {
                  "name": "ControlType",
                  "value": "AnalyticsChart"
                },
                {
                  "name": "SpecificChart",
                  "value": "Line"
                },
                {
                  "name": "TimeRange",
                  "isOptional": true
                },
                {
                  "name": "DashboardId",
                  "isOptional": true
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
              "settings": {
                "content": {
                  "PartTitle": "AKS Node CPU Usage % (${var.aks_name})",
                  "PartSubTitle": "${local.diagnostic_name}",
                  "Query": "// AKSNodeCPU\nlet endDateTime = now();\nlet startDateTime = ago(6h);\nlet trendBinSize = 5m;\nlet capacityCounterName = 'cpuCapacityNanoCores';\nlet usageCounterName = 'cpuUsageNanoCores';\nKubeNodeInventory\n| where ClusterName startswith '${var.aks_name}'\n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\n| distinct ClusterName, Computer\n| join kind= inner (\n  Perf\n  | where TimeGenerated < endDateTime\n  | where TimeGenerated >= startDateTime\n  | where ObjectName == 'K8SNode'\n  | where CounterName == capacityCounterName\n  | summarize LimitValue = max(CounterValue) by Computer, CounterName, bin(TimeGenerated, trendBinSize)\n  | project Computer, CapacityStartTime = TimeGenerated, CapacityEndTime = TimeGenerated + trendBinSize, LimitValue\n) on Computer\n| join kind=inner (\n  Perf\n  | where TimeGenerated < endDateTime + trendBinSize\n  | where TimeGenerated >= startDateTime - trendBinSize\n  | where ObjectName == 'K8SNode'\n  | where CounterName == usageCounterName\n  | project Computer, UsageValue = CounterValue, TimeGenerated\n) on Computer\n| where TimeGenerated >= CapacityStartTime and TimeGenerated < CapacityEndTime\n| project ClusterName, Computer, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\n| summarize CpuUsagePercent = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ClusterName\n//| extend UTCtoPST = TimeGenerated - 7h  // convert UTC to PST\n//| project-away TimeGenerated            // remove the x-axis entry for UTC\n| render timechart\n"
                }
              },
              "asset": {
                "idInputName": "ComponentId",
                "type": "ApplicationInsights"
              }
            }
          },
          "1": {
            "position": {
              "x": 6,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "ComponentId",
                  "value": {
                    "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "ResourceGroup": "${var.input_rg_name}",
                    "Name": "${local.diagnostic_name}",
                    "ResourceId": "${var.diagnostic_resource_id}"
                  }
                },
                {
                  "name": "Query",
                  "value": "// AKSNodeMemory\r\nlet endDateTime = now();\r\nlet startDateTime = ago(6h);\r\nlet trendBinSize = 1m;\r\nlet capacityCounterName = 'memoryCapacityBytes';\r\nlet usageCounterName = 'memoryRssBytes';\r\nKubeNodeInventory\r\n| where ClusterName startswith 'liq' \r\n| where TimeGenerated < endDateTime\r\n| where TimeGenerated >= startDateTime\r\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\r\n| distinct ClusterName, Computer\r\n| join hint.strategy=shuffle (\r\n  Perf\r\n  | where TimeGenerated < endDateTime\r\n  | where TimeGenerated >= startDateTime\r\n  | where ObjectName == 'K8SNode'\r\n  | where CounterName == capacityCounterName\r\n  | summarize LimitValue = max(CounterValue) by Computer, CounterName, bin(TimeGenerated, trendBinSize)\r\n  | project Computer, CapacityStartTime = TimeGenerated, CapacityEndTime = TimeGenerated + trendBinSize, LimitValue\r\n) on Computer\r\n| join kind=inner hint.strategy=shuffle (\r\n  Perf\r\n  | where TimeGenerated < endDateTime + trendBinSize\r\n  | where TimeGenerated >= startDateTime - trendBinSize\r\n  | where ObjectName == 'K8SNode'\r\n  | where CounterName == usageCounterName\r\n  | project Computer, UsageValue = CounterValue, TimeGenerated\r\n) on Computer\r\n| where TimeGenerated >= CapacityStartTime and TimeGenerated < CapacityEndTime\r\n| project ClusterName, Computer, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\r\n| summarize MemoryUsagePercent = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ClusterName\r\n| render timechart \n"
                },
                {
                  "name": "Dimensions",
                  "value": {
                    "xAxis": {
                      "name": "TimeGenerated",
                      "type": "datetime"
                    },
                    "yAxis": [
                      {
                        "name": "MemoryUsagePercent",
                        "type": "real"
                      }
                    ],
                    "splitBy": [
                      {
                        "name": "ClusterName",
                        "type": "string"
                      }
                    ],
                    "aggregation": "Sum"
                  }
                },
                {
                  "name": "Version",
                  "value": "1.0"
                },
                {
                  "name": "PartId",
                  "value": "xxxx"
                },
                {
                  "name": "PartTitle",
                  "value": "Analytics"
                },
                {
                  "name": "PartSubTitle",
                  "value": "${local.diagnostic_name}"
                },
                {
                  "name": "resourceTypeMode",
                  "value": "workspace"
                },
                {
                  "name": "ControlType",
                  "value": "AnalyticsChart"
                },
                {
                  "name": "SpecificChart",
                  "value": "Line"
                },
                {
                  "name": "TimeRange",
                  "isOptional": true
                },
                {
                  "name": "DashboardId",
                  "isOptional": true
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
              "settings": {
                "content": {
                  "PartTitle": "AKS Node Memory Usage % (${var.aks_name})",
                  "PartSubTitle": "${local.diagnostic_name}",
                  "Query": "// AKSNodeMemory\nlet endDateTime = now();\nlet startDateTime = ago(6h);\nlet trendBinSize = 5m;\nlet capacityCounterName = 'memoryCapacityBytes';\nlet usageCounterName = 'memoryRssBytes';\nKubeNodeInventory\n| where ClusterName startswith '${var.aks_name}'\n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\n| distinct ClusterName, Computer\n| join hint.strategy=shuffle (\n  Perf\n  | where TimeGenerated < endDateTime\n  | where TimeGenerated >= startDateTime\n  | where ObjectName == 'K8SNode'\n  | where CounterName == capacityCounterName\n  | summarize LimitValue = max(CounterValue) by Computer, CounterName, bin(TimeGenerated, trendBinSize)\n  | project Computer, CapacityStartTime = TimeGenerated, CapacityEndTime = TimeGenerated + trendBinSize, LimitValue\n) on Computer\n| join kind=inner hint.strategy=shuffle (\n  Perf\n  | where TimeGenerated < endDateTime + trendBinSize\n  | where TimeGenerated >= startDateTime - trendBinSize\n  | where ObjectName == 'K8SNode'\n  | where CounterName == usageCounterName\n  | project Computer, UsageValue = CounterValue, TimeGenerated\n) on Computer\n| where TimeGenerated >= CapacityStartTime and TimeGenerated < CapacityEndTime\n| project ClusterName, Computer, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\n| summarize MemoryUsagePercent = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ClusterName\n| render timechart \n"
                }
              },
              "asset": {
                "idInputName": "ComponentId",
                "type": "ApplicationInsights"
              }
            }
          },
          "2": {
            "position": {
              "x": 0,
              "y": 4,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "ComponentId",
                  "value": {
                    "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "ResourceGroup": "${var.input_rg_name}",
                    "Name": "${local.diagnostic_name}",
                    "ResourceId": "${var.diagnostic_resource_id}"
                  }
                },
                {
                  "name": "Query",
                  "value": "// AksContainerCpuUsage\r\nlet endDateTime = now();\r\nlet startDateTime = ago(6h);\r\nlet trendBinSize = 5m;\r\nlet capacityCounterName = 'cpuLimitNanoCores';\r\nlet usageCounterName = 'cpuUsageNanoCores';\r\n//let clusterName = 'liqk8s190';\r\n//let controllerName = 'emf';\r\nKubePodInventory\r\n| where TimeGenerated < endDateTime\r\n| where TimeGenerated >= startDateTime\r\n//| where ClusterName == clusterName\r\n//| where ControllerName == controllerName\r\n| extend InstanceName = strcat(ClusterId, '/', ContainerName), \r\n         ContainerName = strcat(ControllerName, '/', tostring(split(ContainerName, '/')[1]))\r\n| distinct Computer, InstanceName, ContainerName\r\n| join kind= inner (\r\n    Perf\r\n    | where TimeGenerated < endDateTime\r\n    | where TimeGenerated >= startDateTime\r\n    | where ObjectName == 'K8SContainer'\r\n    | where CounterName == capacityCounterName\r\n    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)\r\n    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue\r\n) on Computer, InstanceName\r\n| join kind=inner (\r\n    Perf\r\n    | where TimeGenerated < endDateTime + trendBinSize\r\n    | where TimeGenerated >= startDateTime - trendBinSize\r\n    | where ObjectName == 'K8SContainer'\r\n    | where CounterName == usageCounterName\r\n    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated\r\n) on Computer, InstanceName\r\n| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime\r\n| project Computer, ContainerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\r\n//| summarize P95 = percentile(UsagePercent, 95) by bin(TimeGenerated, trendBinSize) , ContainerName\r\n| summarize AksContainerCpuUsage = avg(UsagePercent) by bin(TimeGenerated, trendBinSize) , ContainerName\r\n| render timechart\n"
                },
                {
                  "name": "Dimensions",
                  "value": {
                    "xAxis": {
                      "name": "TimeGenerated",
                      "type": "datetime"
                    },
                    "yAxis": [
                      {
                        "name": "AksContainerCpuUsage",
                        "type": "real"
                      }
                    ],
                    "splitBy": [
                      {
                        "name": "ContainerName",
                        "type": "string"
                      }
                    ],
                    "aggregation": "Sum"
                  }
                },
                {
                  "name": "Version",
                  "value": "1.0"
                },
                {
                  "name": "PartId",
                  "value": "xxxx"
                },
                {
                  "name": "PartTitle",
                  "value": "Analytics"
                },
                {
                  "name": "PartSubTitle",
                  "value": "${local.diagnostic_name}"
                },
                {
                  "name": "resourceTypeMode",
                  "value": "workspace"
                },
                {
                  "name": "ControlType",
                  "value": "AnalyticsChart"
                },
                {
                  "name": "SpecificChart",
                  "value": "Line"
                },
                {
                  "name": "TimeRange",
                  "isOptional": true
                },
                {
                  "name": "DashboardId",
                  "isOptional": true
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
              "settings": {
                "content": {
                  "PartTitle": "AKS Container CPU Usage % (${var.aks_name})",
                  "PartSubTitle": "${local.diagnostic_name}",
                  "Query": "// AksContainerCpuUsage\nlet endDateTime = now();\nlet startDateTime = ago(6h);\nlet trendBinSize = 5m;\nlet capacityCounterName = 'cpuLimitNanoCores';\nlet usageCounterName = 'cpuUsageNanoCores';\nlet clusterName = '${var.aks_name}';\n//let controllerName = 'emf';\nKubePodInventory\n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n| where ClusterName == clusterName\n//| where ControllerName == controllerName\n| extend InstanceName = strcat(ClusterId, '/', ContainerName), \n         ContainerName = strcat(ControllerName, '/', tostring(split(ContainerName, '/')[1]))\n| distinct Computer, InstanceName, ContainerName\n| join kind= inner (\n    Perf\n    | where TimeGenerated < endDateTime\n    | where TimeGenerated >= startDateTime\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == capacityCounterName\n    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)\n    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue\n) on Computer, InstanceName\n| join kind=inner (\n    Perf\n    | where TimeGenerated < endDateTime + trendBinSize\n    | where TimeGenerated >= startDateTime - trendBinSize\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == usageCounterName\n    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated\n) on Computer, InstanceName\n| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime\n| project Computer, ContainerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\n//| summarize P95 = percentile(UsagePercent, 95) by bin(TimeGenerated, trendBinSize) , ContainerName\n| summarize AksContainerCpuUsage = avg(UsagePercent) by bin(TimeGenerated, trendBinSize) , ContainerName\n| render timechart\n"
                }
              },
              "asset": {
                "idInputName": "ComponentId",
                "type": "ApplicationInsights"
              }
            }
          },
          "3": {
            "position": {
              "x": 6,
              "y": 4,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "ComponentId",
                  "value": {
                    "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "ResourceGroup": "${var.input_rg_name}",
                    "Name": "${local.diagnostic_name}",
                    "ResourceId": "${var.diagnostic_resource_id}"
                  }
                },
                {
                  "name": "Query",
                  "value": "// AksContainerMemoryUsage\r\nlet endDateTime = now();\r\nlet startDateTime = ago(6h);\r\nlet trendBinSize = 5m;\r\nlet capacityCounterName = 'memoryLimitBytes';\r\nlet usageCounterName = 'memoryRssBytes';\r\n//let clusterName = 'liqk8s190';\r\n//let controllerName = 'emf';\r\nKubePodInventory\r\n| where TimeGenerated < endDateTime\r\n| where TimeGenerated >= startDateTime\r\n//| where ClusterName == clusterName\r\n//| where ControllerName == controllerName\r\n| extend InstanceName = strcat(ClusterId, '/', ContainerName), \r\n         ContainerName = strcat(ControllerName, '/', tostring(split(ContainerName, '/')[1]))\r\n| distinct Computer, InstanceName, ContainerName\r\n| join kind= inner (\r\n    Perf\r\n    | where TimeGenerated < endDateTime\r\n    | where TimeGenerated >= startDateTime\r\n    | where ObjectName == 'K8SContainer'\r\n    | where CounterName == capacityCounterName\r\n    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)\r\n    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue\r\n) on Computer, InstanceName\r\n| join kind=inner (\r\n    Perf\r\n    | where TimeGenerated < endDateTime + trendBinSize\r\n    | where TimeGenerated >= startDateTime - trendBinSize\r\n    | where ObjectName == 'K8SContainer'\r\n    | where CounterName == usageCounterName\r\n    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated\r\n) on Computer, InstanceName\r\n| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime\r\n| project Computer, ContainerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\r\n//| summarize P95 = percentile(UsagePercent, 95) by bin(TimeGenerated, trendBinSize) , ContainerName\r\n| summarize AksContainerMemoryUsage = avg(UsagePercent) by bin(TimeGenerated, trendBinSize) , ContainerName\r\n| render timechart\n"
                },
                {
                  "name": "Dimensions",
                  "value": {
                    "xAxis": {
                      "name": "TimeGenerated",
                      "type": "datetime"
                    },
                    "yAxis": [
                      {
                        "name": "AksContainerMemoryUsage",
                        "type": "real"
                      }
                    ],
                    "splitBy": [
                      {
                        "name": "ContainerName",
                        "type": "string"
                      }
                    ],
                    "aggregation": "Sum"
                  }
                },
                {
                  "name": "Version",
                  "value": "1.0"
                },
                {
                  "name": "PartId",
                  "value": "xxxx"
                },
                {
                  "name": "PartTitle",
                  "value": "Analytics"
                },
                {
                  "name": "PartSubTitle",
                  "value": "${local.diagnostic_name}"
                },
                {
                  "name": "resourceTypeMode",
                  "value": "workspace"
                },
                {
                  "name": "ControlType",
                  "value": "AnalyticsChart"
                },
                {
                  "name": "SpecificChart",
                  "value": "Line"
                },
                {
                  "name": "TimeRange",
                  "isOptional": true
                },
                {
                  "name": "DashboardId",
                  "isOptional": true
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
              "settings": {
                "content": {
                  "PartTitle": "AKS Container Memory Usage % (${var.aks_name})",
                  "PartSubTitle": "${local.diagnostic_name}",
                  "Query": "// AksContainerMemoryUsage\nlet endDateTime = now();\nlet startDateTime = ago(6h);\nlet trendBinSize = 5m;\nlet capacityCounterName = 'memoryLimitBytes';\nlet usageCounterName = 'memoryRssBytes';\nlet clusterName = '${var.aks_name}';\n//let controllerName = 'emf';\nKubePodInventory\n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n| where ClusterName == clusterName\n//| where ControllerName == controllerName\n| extend InstanceName = strcat(ClusterId, '/', ContainerName), \n         ContainerName = strcat(ControllerName, '/', tostring(split(ContainerName, '/')[1]))\n| distinct Computer, InstanceName, ContainerName\n| join kind= inner (\n    Perf\n    | where TimeGenerated < endDateTime\n    | where TimeGenerated >= startDateTime\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == capacityCounterName\n    | summarize LimitValue = max(CounterValue) by Computer, InstanceName, bin(TimeGenerated, trendBinSize)\n    | project Computer, InstanceName, LimitStartTime = TimeGenerated, LimitEndTime = TimeGenerated + trendBinSize, LimitValue\n) on Computer, InstanceName\n| join kind=inner (\n    Perf\n    | where TimeGenerated < endDateTime + trendBinSize\n    | where TimeGenerated >= startDateTime - trendBinSize\n    | where ObjectName == 'K8SContainer'\n    | where CounterName == usageCounterName\n    | project Computer, InstanceName, UsageValue = CounterValue, TimeGenerated\n) on Computer, InstanceName\n| where TimeGenerated >= LimitStartTime and TimeGenerated < LimitEndTime\n| project Computer, ContainerName, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue\n//| summarize P95 = percentile(UsagePercent, 95) by bin(TimeGenerated, trendBinSize) , ContainerName\n| summarize AksContainerMemoryUsage = avg(UsagePercent) by bin(TimeGenerated, trendBinSize) , ContainerName\n| render timechart\n"
                }
              },
              "asset": {
                "idInputName": "ComponentId",
                "type": "ApplicationInsights"
              }
            }
          },
          "4": {
            "position": {
              "x": 0,
              "y": 8,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "ComponentId",
                  "value": {
                    "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "ResourceGroup": "${var.input_rg_name}",
                    "Name": "${local.diagnostic_name}",
                    "ResourceId": "${var.diagnostic_resource_id}"
                  }
                },
                {
                  "name": "Query",
                  "value": "// GkeContainerCpuUsage\r\nlet endDateTime = now();\r\nlet startDateTime = ago(6h);\r\nlet trendBinSize = 5m;\r\nlet usageCounterName = '% Processor Time';\r\nContainerInventory\r\n| where Computer startswith 'gke' \r\n| where Name contains \"emf\" \r\n//| where Image contains \"emf\" \r\n| where TimeGenerated < endDateTime\r\n| where TimeGenerated >= startDateTime\r\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\r\n| distinct Name, Image, Computer\r\n| join kind= inner (\r\n  Perf\r\n  | where TimeGenerated < endDateTime\r\n  | where TimeGenerated >= startDateTime\r\n  | where ObjectName == 'Container'\r\n  | where CounterName == usageCounterName\r\n  | project Computer, CounterValue, TimeGenerated, InstanceName \r\n  ) on Computer\r\n| summarize GkeCpuUsage = max(CounterValue) by bin(TimeGenerated, trendBinSize), Name\r\n| render timechart\n"
                },
                {
                  "name": "Dimensions",
                  "value": {
                    "xAxis": {
                      "name": "TimeGenerated",
                      "type": "datetime"
                    },
                    "yAxis": [
                      {
                        "name": "GkeCpuUsage",
                        "type": "real"
                      }
                    ],
                    "splitBy": [
                      {
                        "name": "Name",
                        "type": "string"
                      }
                    ],
                    "aggregation": "Sum"
                  }
                },
                {
                  "name": "Version",
                  "value": "1.0"
                },
                {
                  "name": "PartId",
                  "value": "xxxx"
                },
                {
                  "name": "PartTitle",
                  "value": "Analytics"
                },
                {
                  "name": "PartSubTitle",
                  "value": "${local.diagnostic_name}"
                },
                {
                  "name": "resourceTypeMode",
                  "value": "workspace"
                },
                {
                  "name": "ControlType",
                  "value": "AnalyticsChart"
                },
                {
                  "name": "SpecificChart",
                  "value": "Line"
                },
                {
                  "name": "TimeRange",
                  "isOptional": true
                },
                {
                  "name": "DashboardId",
                  "isOptional": true
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
              "settings": {
                "content": {
                  "PartTitle": "GKE Container CPU Usage % (${var.gk_name})",
                  "PartSubTitle": "${local.diagnostic_name}",
                  "Query": "// GkeContainerCpuUsage\nlet endDateTime = now();\nlet startDateTime = ago(6h);\nlet trendBinSize = 5m;\nlet usageCounterName = '% Processor Time';\nContainerInventory\n| where Computer startswith '${var.gk_name}' \n| where Name contains \"emf\" \n//| where Image contains \"emf\" \n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\n| distinct Name, Image, Computer\n| join kind= inner (\n  Perf\n  | where TimeGenerated < endDateTime\n  | where TimeGenerated >= startDateTime\n  | where ObjectName == 'Container'\n  | where CounterName == usageCounterName\n  | project Computer, CounterValue, TimeGenerated, InstanceName \n  ) on Computer\n| summarize GkeCpuUsage = max(CounterValue) by bin(TimeGenerated, trendBinSize), Name\n| render timechart\n"
                }
              },
              "asset": {
                "idInputName": "ComponentId",
                "type": "ApplicationInsights"
              }
            }
          },
          "5": {
            "position": {
              "x": 6,
              "y": 8,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "ComponentId",
                  "value": {
                    "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                    "ResourceGroup": "${var.input_rg_name}",
                    "Name": "${local.diagnostic_name}",
                    "ResourceId": "${var.diagnostic_resource_id}"
                  }
                },
                {
                  "name": "Query",
                  "value": "// GkeContainerMemoryUsage\r\nlet endDateTime = now();\r\nlet startDateTime = ago(6h);\r\nlet trendBinSize = 5m;\r\nlet usageCounterName = 'Memory Usage MB';\r\nContainerInventory\r\n| where Computer startswith 'gke' \r\n| where Name contains \"emf\" \r\n//| where Image contains \"emf\" \r\n| where TimeGenerated < endDateTime\r\n| where TimeGenerated >= startDateTime\r\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\r\n| distinct Name, Image, Computer\r\n| join kind= inner (\r\n  Perf\r\n  | where TimeGenerated < endDateTime\r\n  | where TimeGenerated >= startDateTime\r\n  | where ObjectName == 'Container'\r\n  | where CounterName == usageCounterName\r\n  | project Computer, CounterValue, TimeGenerated, InstanceName \r\n  ) on Computer\r\n| summarize MemoryUsageMb = avg(CounterValue) by bin(TimeGenerated, trendBinSize), Name\r\n| render timechart\n"
                },
                {
                  "name": "Dimensions",
                  "value": {
                    "xAxis": {
                      "name": "TimeGenerated",
                      "type": "datetime"
                    },
                    "yAxis": [
                      {
                        "name": "MemoryUsageMb",
                        "type": "real"
                      }
                    ],
                    "splitBy": [
                      {
                        "name": "Name",
                        "type": "string"
                      }
                    ],
                    "aggregation": "Sum"
                  }
                },
                {
                  "name": "Version",
                  "value": "1.0"
                },
                {
                  "name": "PartId",
                  "value": "xxxx"
                },
                {
                  "name": "PartTitle",
                  "value": "Analytics"
                },
                {
                  "name": "PartSubTitle",
                  "value": "${local.diagnostic_name}"
                },
                {
                  "name": "resourceTypeMode",
                  "value": "workspace"
                },
                {
                  "name": "ControlType",
                  "value": "AnalyticsChart"
                },
                {
                  "name": "SpecificChart",
                  "value": "Line"
                },
                {
                  "name": "TimeRange",
                  "isOptional": true
                },
                {
                  "name": "DashboardId",
                  "isOptional": true
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AnalyticsPart",
              "settings": {
                "content": {
                  "PartTitle": "GKE Container Memory Usage Mb (${var.gk_name})",
                  "PartSubTitle": "${local.diagnostic_name}",
                  "Query": "// GkeContainerMemoryUsage\nlet endDateTime = now();\nlet startDateTime = ago(6h);\nlet trendBinSize = 5m;\nlet usageCounterName = 'Memory Usage MB';\nContainerInventory\n| where Computer startswith '${var.gk_name}' \n| where Name contains \"emf\" \n//| where Image contains \"emf\" \n| where TimeGenerated < endDateTime\n| where TimeGenerated >= startDateTime\n// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace\n| distinct Name, Image, Computer\n| join kind= inner (\n  Perf\n  | where TimeGenerated < endDateTime\n  | where TimeGenerated >= startDateTime\n  | where ObjectName == 'Container'\n  | where CounterName == usageCounterName\n  | project Computer, CounterValue, TimeGenerated, InstanceName \n  ) on Computer\n| summarize MemoryUsageMb = max(CounterValue) by bin(TimeGenerated, trendBinSize), Name\n| render timechart\n"
                }
              },
              "asset": {
                "idInputName": "ComponentId",
                "type": "ApplicationInsights"
              }
            }
          }
        }
      }
    },
    "metadata": {
      "model": {
        "timeRange": {
          "value": {
            "relative": {
              "duration": 24,
              "timeUnit": 1
            }
          },
          "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        },
        "filterLocale": {
          "value": "en-us"
        },
        "filters": {
          "value": {
            "MsPortalFx_TimeRange": {
              "model": {
                "format": "utc",
                "granularity": "auto",
                "relative": "24h"
              },
              "displayCache": {
                "name": "UTC Time",
                "value": "Past 24 hours"
              },
              "filteredPartIds": [
                "StartboardPart-AnalyticsPart-xxxx",
                "StartboardPart-AnalyticsPart-xxxx",
                "StartboardPart-AnalyticsPart-xxx9",
                "StartboardPart-AnalyticsPart-xxxb",
                "StartboardPart-AnalyticsPart-xxxd",
                "StartboardPart-AnalyticsPart-xxxf"
              ]
            }
          }
        }
      }
    }
  }
DASH
    }
