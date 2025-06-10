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