#Role Assignment

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}

resource "azurerm_role_assignment" "az_role_assgn_vm" {
  scope              = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.resource_group}"
  role_definition_name = "Contributor"
  principal_id       = azurerm_virtual_machine.dev-vm.identity.0.principal_id
}

resource "azurerm_role_assignment" "az_role_assgn_identity" {
  scope              = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.resource_group}"
  role_definition_name = "Owner"
  principal_id       = azurerm_user_assigned_identity.user_id.principal_id
  depends_on = [azurerm_resource_group.azuregoat, 
    azurerm_user_assigned_identity.user_id
  ]
}


resource "azurerm_user_assigned_identity" "user_id" {
  resource_group_name = var.resource_group
  location              = var.region
  depends_on = [azurerm_resource_group.azuregoat]

  name = "user-assigned-id${var.cgid}"
}

resource "azurerm_automation_account" "dev_automation_account_test" {
  name                = "dev-automation-account-${var.cgid}"
  location              = var.region
  resource_group_name = var.resource_group
  sku_name            = "Basic"
    identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_id.id]
  }

  tags = {
    environment = "development"
  }
}
