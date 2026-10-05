# 1. Create the Azure Databricks Access Connector
# This acts as a Managed Identity for Unity Catalog to securely access ADLS Gen2.
resource "azurerm_databricks_access_connector" "uc_access" {
  name                = "dbac-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# 2. Grant the Access Connector 'Storage Blob Data Contributor' on ADLS
# This gives Unity Catalog the permission to read and write data to the data lake.
resource "azurerm_role_assignment" "uc_adls_access" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.uc_access.identity[0].principal_id
}

# 3. Unity Catalog Storage Credential (Databricks Resource)
# Registers the Access Connector inside the Databricks workspace.
resource "databricks_storage_credential" "uc_cred" {
  name = "cred-${var.project_name}-${var.environment}"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.uc_access.id
  }
  comment = "Managed identity credential for Unity Catalog"
}

# 4. Unity Catalog External Location (Databricks Resource)
# Points Databricks Unity Catalog to the 'lab-data' container we created in main.tf.
resource "databricks_external_location" "lab_data_loc" {
  name            = "ext-loc-lab-data"
  url             = "abfss://lab-data@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.uc_cred.id
  comment         = "External location for Spark Skew Optimization Lab"
  
  # We must wait for the role assignment to finish before Databricks can validate the location.
  depends_on = [
    azurerm_role_assignment.uc_adls_access
  ]
}
