# Deploy Azure Dashboard for AKS & GKE Clusters
To implement a dashboard, take the following steps by referring the documents:
## Create Kusto log queries in the Log Analytics Workspace
- https://docs.microsoft.com/en-us/azure/azure-monitor/log-query/get-started-queries
- https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-log-search
- https://docs.microsoft.com/en-us/azure/azure-monitor/log-query/query-language
- https://docs.microsoft.com/en-us/azure/azure-monitor/log-query/charts
## Create a shared dashboard in Azure portal
- https://docs.microsoft.com/en-us/azure/azure-monitor/learn/tutorial-logs-dashboards
- https://docs.microsoft.com/en-us/azure/azure-monitor/learn/tutorial-app-dashboards
## Pin the successful log query to the created dashboard
## Download the dashboard JSON file
## Compose a Terraform file using the dashboard JSON file
- https://www.terraform.io/docs/providers/azurerm/r/dashboard.html
## Azure Monitor Kusto Query Samples
- https://github.com/Azure/k8s-best-practices/blob/master/aks-azure-monitor/examples
- https://stackoverflow.com/questions/54569778/azure-aks-monitoring-custom-dashboard-resources
