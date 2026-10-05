# 1. Key Vault Access Policy for the Terraform Runner
# This ensures whoever runs 'terraform apply' has permission to manage secrets.
resource "azurerm_key_vault_access_policy" "terraform_runner" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
}

# 2. Store ADLS Storage Account Key in Key Vault
# Automatically grabs the primary access key of the data lake and saves it as a secret.
# The 'depends_on' ensures the access policy exists BEFORE trying to write the secret.
resource "azurerm_key_vault_secret" "adls_key" {
  name         = "adls-access-key"
  value        = azurerm_storage_account.adls.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.terraform_runner]
}

# 3. Store Databricks Workspace URL in Key Vault (Useful for CI/CD pipelines later)
resource "azurerm_key_vault_secret" "dbw_url" {
  name         = "databricks-workspace-url"
  value        = azurerm_databricks_workspace.dbw.workspace_url
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.terraform_runner]
}

# 4. Role Assignment: Storage Blob Data Contributor
# Grants your user account data-plane access to read/write files in ADLS Gen2.
resource "azurerm_role_assignment" "data_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
