# az login
# az ad sp create-for-rbac --name osba -o table
# AppId is client_id
provider "azurerm" {
    subscription_id = "xxxxx"
    client_id       = "xxxxx"
    client_secret   = "xxxxx"
    tenant_id       = "xxxxx"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "lizTestRG"
    location = "eastus"

    tags = {
        environment = "Terraform Demo1"
    }
}