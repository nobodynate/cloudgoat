resource "null_resource" "file_populate_data" {
  provisioner "local-exec" {
    command     = <<EOF
sed -i 's/AZURE_FUNCTION_URL/${azurerm_storage_account.storage_account.name}\.blob\.core\.windows\.net\/${azurerm_storage_container.storage_container_prod.name}/g' ../assets/resources/cosmosdb/blog-posts.json
python3 -m venv azure-goat-environment
source azure-goat-environment/bin/activate
pip3 install --pre azure-cosmos
python3 ../assets/resources/cosmosdb/create-table.py
EOF
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [azurerm_resource_group.azuregoat, azurerm_cosmosdb_account.db,azurerm_storage_account.storage_account,azurerm_storage_container.storage_container]
}

resource "null_resource" "env_replace" {
  provisioner "local-exec" {
    command     = <<EOF
pwd
sed -i 's`AZ_DB_PRIMARYKEY_REPLACE`${azurerm_cosmosdb_account.db.primary_key}`' ../assets/resources/azure_function/data/local.settings.json
sed -i 's`AZ_DB_ENDPOINT_REPLACE`${azurerm_cosmosdb_account.db.endpoint}`' ../assets/resources/azure_function/data/local.settings.json
sed -i 's`CON_STR_REPLACE`${azurerm_storage_account.storage_account.primary_connection_string}`' ../assets/resources/azure_function/data/local.settings.json
sed -i 's`CONTAINER_NAME_REPLACE`${azurerm_storage_container.storage_container.name}`' ../assets/resources/azure_function/data/local.settings.json

EOF
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [azurerm_resource_group.azuregoat, azurerm_cosmosdb_account.db,azurerm_storage_account.storage_account,azurerm_storage_container.storage_container]
}

resource "null_resource" "clientid_replacement" {
    provisioner "local-exec" {
    command     = <<EOF
sed -i 's/REPLACE_CLIENT_ID/${azurerm_user_assigned_identity.user_id.client_id}/g' ../assets/resources/vm/listVM.ps1
sed -i 's/REPLACE_RESOURCE_GROUP_NAME/${var.resource_group}/g' ../assets/resources/vm/listVM.ps1
EOF
    interpreter = ["/bin/bash", "-c"]
  }
}

