resource "azurerm_resource_group" "azuregoat" {
  name     = var.resource_group
  location = var.region
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "ine-cosmos-db-data-${vars.gcid}"
  location            = var.region
  resource_group_name = var.resource_group
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  depends_on = [azurerm_resource_group.azuregoat]

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  capabilities {
    name = "EnableServerless"
  }

  geo_location {
    location          = var.region
    failover_priority = 0
  }
}


resource "azurerm_storage_account" "storage_account" {
  name = "appazgoat${vars.gcid}storage"
  resource_group_name = var.resource_group
  location = var.region
  account_tier = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  blob_properties{
    cors_rule{
        allowed_headers = ["*"]
        allowed_methods = ["GET","HEAD","POST","PUT"]
        allowed_origins = ["*"]
        exposed_headers = ["*"]
        max_age_in_seconds = 3600
        }
    }
  depends_on = [azurerm_resource_group.azuregoat]
}

resource "azurerm_storage_container" "storage_container" {
    name = "appazgoat${vars.gcid}-storage-container"
    storage_account_id = azurerm_storage_account.storage_account.id
    container_access_type = "blob"
}

resource "azurerm_storage_blob" "storage_blob" {
  name = "../assets/resources/azure_function/data/data-api.zip"
  storage_account_name = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.storage_container.name
  type = "Block"
  source = "../assets/resources/azure_function/data/data-api.zip"
  depends_on = [azurerm_resource_group.azuregoat, data.archive_file.file_function_app, azurerm_storage_container.storage_container]
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "appazgoat${vars.gcid}-app-service-plan"
  resource_group_name = var.resource_group
  location            = var.region
  os_type             = "Linux"  # Required
  sku_name            = "B1"     # Required

  depends_on = [azurerm_resource_group.azuregoat]
}

resource "azurerm_linux_function_app" "function_app" {
  name                       = "appazgoat${vars.gcid}-function"
  resource_group_name        = var.resource_group
  location                   = var.region
  service_plan_id            = azurerm_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.storage_account.id}.blob.core.windows.net/${azurerm_storage_container.storage_container.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas.sas}",
    "FUNCTIONS_WORKER_RUNTIME" = "python",
    "JWT_SECRET"               = "T2BYL6#]zc>Byuzu",
    "AZ_DB_ENDPOINT"           = azurerm_cosmosdb_account.db.endpoint,
    "AZ_DB_PRIMARYKEY"         = azurerm_cosmosdb_account.db.primary_key,
    "CON_STR"                  = azurerm_storage_account.storage_account.primary_connection_string,
    "CONTAINER_NAME"           = azurerm_storage_container.storage_container.name
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
    cors {
      allowed_origins = ["*"]
    }
  }
  depends_on = [azurerm_resource_group.azuregoat, azurerm_cosmosdb_account.db,azurerm_storage_account.storage_account,null_resource.env_replace]
}

resource "azurerm_automation_runbook" "dev_automation_runbook" {
  name                    = "Get-AzureVM"
  location              = var.region
  resource_group_name     = var.resource_group
  automation_account_name = azurerm_automation_account.dev_automation_account_test.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This is an example runbook"
  runbook_type            = "PowerShellWorkflow"
  content = data.local_file.runbook_file.content
}