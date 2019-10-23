data "azurerm_subscription" "current" {}

variable "dashboard_name" {
  description = "the name of the dashboard"
  default = "K8S_Cluster_Dashboard"
}

variable "rg_name" {
  description = "resource group name to put the dashboard"
  default     = "rg1"
}

variable "rg_location" {
  description = "resource location"
  default     = "West US"
}

variable "input_rg_name" {
  description = "Log analytics workspace resource group name"
  default = "rg2"
}

variable "diagnostic_resource_id" {
  description = "Log analytics workspace resource ID."
  type        = string
  default = "/subscriptions/xxxx/resourcegroups/devops2/providers/microsoft.operationalinsights/workspaces/diagnostic-xxxx"
}

variable "aks_name" {
    description = "AKS name"
    type        = string
	default = "aksname"
}

variable "gk_name"{
    description = "Kubernetes Cluster name project name"
    type = string
	default = "gkename"
}

//Will be extracted from diagnostic_resource_id
//variable "diagnostic_name" {
//  description = "input name"
//  default = "defaultworkspace-xxxx-wus"
//  default = "diagnostic-xxx"
//}
