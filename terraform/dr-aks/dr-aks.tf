###############################################################
# Create Resource Group
###############################################################

resource "azurerm_resource_group" "rg" {
  name     = "dr-rg"
  location = "West Europe"
  
  tags = {
    environment = "Demo"
  }
}

###############################################################
# Create AKS
###############################################################

resource "azurerm_kubernetes_cluster" "primary" {
  name                 = "dr-aks"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  dns_prefix           = "dr-azure-k8s"
  private_cluster_enabled = false
  sku_tier             = "Free"


  #Enable OIDC + Workload Identity
  oidc_issuer_enabled         = true
  workload_identity_enabled   = true 

  
  default_node_pool {
    name                 = "aksnodepool"
    node_count           = 2
    vm_size              = "Standard_D2_v3"
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
  }
  
  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  api_server_access_profile {
    authorized_ip_ranges = ["x.x.x.x"]
  }

}
