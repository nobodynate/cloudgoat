# Storage Accounts Config
#################################################################################
locals {
  mime_types = {
    "css"  = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
    "pub"  = "text/plain"
    "pem"  = "text/plain"
    "sh" = "text/x-shellscript"
  }
}


resource "azurerm_storage_container" "storage_container_prod" {
  name                  = "prod-appazgoat${random_id.randomId.dec}-storage-container"
  storage_account_id  = azurerm_storage_account.storage_account.id
  container_access_type = "blob"
}


resource "azurerm_storage_container" "storage_container_dev" {
  name                  = "dev-appazgoat${random_id.randomId.dec}-storage-container"
  storage_account_id  = azurerm_storage_account.storage_account.id
  container_access_type = "container"
}

resource "azurerm_storage_container" "storage_container_vm" {
  name                  = "vm-appazgoat${random_id.randomId.dec}-storage-container"
  storage_account_id  = azurerm_storage_account.storage_account.id
  container_access_type = "container"
}



resource "null_resource" "file_replacement_upload" {
  provisioner "local-exec" {
    command     = <<EOF
pwd
sed -i 's/="\//="https:\/\/${azurerm_storage_account.storage_account.id}\.blob\.core\.windows\.net\/${azurerm_storage_container.storage_container_prod.name}\/webfiles\/build\//g' ../assets/resources/azure_function/react/webapp/index.html
sed -i 's/"\/static/"https:\/\/${azurerm_storage_account.storage_account.id}\.blob\.core\.windows\.net\/${azurerm_storage_container.storage_container_prod.name}\/webfiles\/build\/static/g' ../assets/resources/storage_account/webfiles/build/static/js/main.adc6b28e.js
sed -i 's/"\/static/"https:\/\/${azurerm_storage_account.storage_account.id}\.blob\.core\.windows\.net\/${azurerm_storage_container.storage_container_prod.name}\/webfiles\/build\/static/g' ../assets/resources/storage_account/webfiles/build/static/js/main.adc6b28e.js
sed -i 's/n.p+"static/"https:\/\/${azurerm_storage_account.storage_account.id}\.blob\.core\.windows\.net\/${azurerm_storage_container.storage_container_prod.name}\/webfiles\/build\/static/g' ../assets/resources/storage_account/webfiles/build/static/js/main.adc6b28e.js
sed -i "s,AZURE_FUNCTION_URL,https:\/\/${azurerm_linux_function_app.function_app.default_hostname},g" ../assets/resources/storage_account/webfiles/build/static/js/main.adc6b28e.js
EOF 
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [azurerm_resource_group.azuregoat, data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas,azurerm_storage_container.storage_container,azurerm_storage_account.storage_account]
}

resource "azurerm_storage_blob" "app_files_prod" {
  for_each               = fileset("./../assets/resources/storage_account/", "**")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_prod.name
  content_type           = lookup(tomap(local.mime_types), element(split(".", each.value), length(split(".", each.value)) - 1))
  type                   = "Block"
  source                 = "./../assets/resources/storage_account/${each.value}"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_upload,azurerm_storage_container.storage_container_prod]
}

resource "azurerm_storage_blob" "app_files_dev" {
  for_each               = fileset("./../assets/resources/storage_account/", "**")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_dev.name
  content_type           = lookup(tomap(local.mime_types), element(split(".", each.value), length(split(".", each.value)) - 1))
  type                   = "Block"
  source                 = "./../assets/resources/storage_account/${each.value}"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_upload,azurerm_storage_container.storage_container_dev]
}



resource "azurerm_storage_blob" "app_files_vm" {
  for_each               = fileset("./../assets/resources/storage_account/", "**")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_vm.name
  content_type           = lookup(tomap(local.mime_types), element(split(".", each.value), length(split(".", each.value)) - 1))
  type                   = "Block"
  source                 = "./../assets/resources/storage_account/${each.value}"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_upload,azurerm_storage_container.storage_container_vm]
}
