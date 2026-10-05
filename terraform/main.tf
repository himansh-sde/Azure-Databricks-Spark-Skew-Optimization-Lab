# Fetch current user/service principal details (needed for Key Vault access policies in iam.tf)
data "azurerm_client_config" "current" {}

# Helper: Random string to ensure globally unique names for Storage and Key Vault
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# 2. Azure Data Lake Storage Gen2
resource "azurerm_storage_account" "adls" {
  name                     = "st${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Enables hierarchical namespace for ADLS Gen2
  tags                     = var.tags
}

# Create all ADLS containers dynamically based on the list in variables.tf
resource "azurerm_storage_data_lake_gen2_filesystem" "containers" {
  for_each           = toset(var.adls_containers)
  name               = each.key
  storage_account_id = azurerm_storage_account.adls.id
}

# 3. Azure Databricks Workspace
resource "azurerm_databricks_workspace" "dbw" {
  name                = "dbw-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium" # Required for Unity Catalog and advanced IAM
  tags                = var.tags
}

# 4. Azure Key Vault (Core Resource only)
resource "azurerm_key_vault" "kv" {
  name                        = "kv-${var.project_name}-${random_string.suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags
}
