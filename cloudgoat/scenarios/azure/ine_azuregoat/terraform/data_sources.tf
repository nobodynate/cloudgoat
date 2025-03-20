data "azurerm_subscription" "current" {}

data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas" {
  connection_string = azurerm_storage_account.storage_account.primary_connection_string
  container_name    = azurerm_storage_container.storage_container.name
  start  = "${local.date_now}"
  expiry = "${local.date_br}"
  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = false
    list   = false
  }
}

data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../assets/resources/azure_function/data"
  output_path = "../assets/resources/azure_function/data/data-api.zip"
  depends_on = [azurerm_resource_group.azuregoat, 
    null_resource.env_replace
  ]
}

data "local_file" "runbook_file" {
  filename = "../assets/resources/vm/listVM.ps1"
depends_on = [azurerm_resource_group.azuregoat, 
  null_resource.clientid_replacement
]
}
