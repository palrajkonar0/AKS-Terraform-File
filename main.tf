terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "ccde0b25-b731-439f-bce8-5ef8b917a848"
  
}

data "azurerm_resource_group" "rg" {
  name     = "Sushant"
}

data "azurerm_resource_group" "vnet_rg" {
  name = "RG-SANDBOX-CI"
}

data "azurerm_virtual_network" "vnet" {
  name = "SandBox-CI-VNET"
  resource_group_name = data.azurerm_resource_group.vnet_rg.name
}

resource "azurerm_subnet" "palraj" {
  name = "palraj"
  address_prefixes = ["172.22.65.64/26"]
  resource_group_name = data.azurerm_resource_group.vnet_rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "Test-Cluster"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aksfree"  
  sku_tier            = "Free"

  default_node_pool {
    name       = "test"
    node_count = 1
    vm_size    = "Standard_D2as_v5" # Low-cost VM for free tier
    vnet_subnet_id = azurerm_subnet.palraj.id
    os_sku = "Ubuntu"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  tags = {
    Environment = "Dev"
  }
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}