# Fetch current user/service principal details (needed for Key Vault access)
data "azurerm_client_config" "current" {}

# 1. Resource Group (The container for all your resources)
resource "azurerm_resource_group" "rg" {
  name     = "rg-spark-optimization-lab"
  location = "Central India"
}

# 2. Azure Data Lake Storage Gen2
resource "azurerm_storage_account" "adls" {
  name                     = "stsparkoptlab${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # This flag makes it ADLS Gen2 instead of standard blob storage
}

resource "azurerm_storage_data_lake_gen2_filesystem" "data" {
  name               = "lab-data"
  storage_account_id = azurerm_storage_account.adls.id
}

# 3. Azure Databricks Workspace
resource "azurerm_databricks_workspace" "dbw" {
  name                = "dbw-spark-optimization-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}

# 4. Azure Key Vault (To securely store secrets like ADLS access keys)
resource "azurerm_key_vault" "kv" {
  name                        = "kv-sparkoptlab-${random_string.suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Grants the person running the Terraform script permission to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }
}

# Helper: Random string to ensure globally unique names for Storage and Key Vault
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
