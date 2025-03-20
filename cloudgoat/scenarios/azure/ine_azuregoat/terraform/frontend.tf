
###########################frontend########################################

data "archive_file" "file_function_app_front" {
  type        = "zip"
  source_dir  = "../assets/resources/azure_function/react"
  output_path = "../assets/resources/azure_function/react/func.zip"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_upload]
}

resource "azurerm_storage_blob" "storage_blob_front" {
  name = "../assets/resources/azure_function/react/func.zip"
  storage_account_name = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container.name
  type = "Block"
  source = "../assets/resources/azure_function/react/func.zip"
  depends_on = [azurerm_resource_group.azuregoat, data.archive_file.file_function_app_front,azurerm_storage_container.storage_container]
}


resource "azurerm_function_app" "function_app_front" {
  name                       = "appazgoat${random_id.randomId.dec}-function-app"
  resource_group_name        = var.resource_group
  location                   = var.region
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "https://${azurerm_storage_account.storage_account.name}.blob.core.windows.net/${azurerm_storage_container.storage_container.name}/${azurerm_storage_blob.storage_blob_front.name}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas.sas}",
    FUNCTIONS_WORKER_RUNTIME = "node",
    "AzureWebJobsDisableHomepage" = "true",
  }
  os_type = "linux"
  site_config {
    linux_fx_version = "node|12"
    use_32_bit_worker_process = false
  }
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_upload]
}

resource "null_resource" "file_replacement_vm_ip" {
  provisioner "local-exec" {
    command     = "sed -i 's/VM_IP_ADDR/${data.azurerm_public_ip.vm_ip.ip_address}/g' ../assets/resources/storage_account/shared/files/.ssh/config.txt"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [azurerm_resource_group.azuregoat, azurerm_virtual_machine.dev-vm,data.azurerm_public_ip.vm_ip]
}
resource "azurerm_storage_blob" "config_update_prod" {
  name                   = "../assets/resources/storage_account/shared/files/.ssh/config.txt"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_prod.name
  type                   = "Block"
  source                 = "../assets/resources/storage_account/shared/files/.ssh/config.txt"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_vm_ip, azurerm_storage_container.storage_container]
}

resource "azurerm_storage_blob" "config_update_dev" {
  name                   = "../assets/resources/storage_account/shared/files/.ssh/config.txt"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_dev.name
  type                   = "Block"
  source                 = "../assets/resources/storage_account/shared/files/.ssh/config.txt"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_vm_ip, azurerm_storage_container.storage_container]
}

resource "azurerm_storage_blob" "config_update_vm" {
  name                   = "../assets/resources/storage_account/shared/files/.ssh/config.txt"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_vm.name
  type                   = "Block"
  source                 = "../assets/resources/storage_account/shared/files/.ssh/config.txt"
  depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_vm_ip, azurerm_storage_container.storage_container]
}
  
output "Target_URL"{
  value = "https://${azurerm_function_app.function_app_front.name}.azurewebsites.net"
}
    
