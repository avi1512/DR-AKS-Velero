##################################################
#Creating Storage Account And Blob Container
###############################################

resource "azurerm_storage_account" "sa" {
  name                     = "k8sbackupstorage2" # must be globally unique and 3-24 lowercase letters/numbers
  resource_group_name      = "primary-rg"
  location                 = "Central India"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = {
    environment = "backup"
  }
}

resource "azurerm_storage_container" "blob" {
  name                  = "k8s-backup"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}


#########################################################
#Create User-Assigned Managed Identity
#########################################################
resource "azurerm_user_assigned_identity" "blob_cleaner_mi" {
  name                = "blob-cleaner-identity"
  resource_group_name = "primary-rg"
  location            = "Central India"
}


#########################################################
# Grant Role to Managed Identity on Storage Account
#########################################################
resource "azurerm_role_assignment" "blob_data_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.blob_cleaner_mi.principal_id
}


#########################################################
#Federated Identity Credential (Link SA to Identity)
#########################################################
resource "azurerm_federated_identity_credential" "blob_cleaner_federation" {
  name                = "blob-cleaner-federation"
  resource_group_name = azurerm_user_assigned_identity.blob_cleaner_mi.resource_group_name
  parent_id           = azurerm_user_assigned_identity.blob_cleaner_mi.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  subject             = "system:serviceaccount:velero:azure-blob-cleaner-sa"
}
