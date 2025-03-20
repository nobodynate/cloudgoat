# VM Config
#################################################################################
# Security group
resource "azurerm_network_security_group" "net_sg" {
  name                = "SecGroupNet${var.cgid}"
  location            = var.region
  resource_group_name = var.resource_group

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.azuregoat]

}


# Virtual network
resource "azurerm_virtual_network" "vNet" {
  name                = "vNet${var.cgid}"
  address_space       = ["10.1.0.0/16"]
  location            = var.region
  resource_group_name = var.resource_group
  depends_on = [azurerm_resource_group.azuregoat]

}
resource "azurerm_subnet" "vNet_subnet" {
  name                 = "Subnet${var.cgid}"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vNet.name
  address_prefixes     = ["10.1.0.0/24"]
  depends_on = [azurerm_resource_group.azuregoat, 
    azurerm_virtual_network.vNet
  ]
}

#public ip
resource "azurerm_public_ip" "VM_PublicIP" {
  name                    = "developerVMPublicIP${var.cgid}"
  resource_group_name     = var.resource_group
  location                = var.region
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 4
  domain_name_label       = lower("developervm-${var.cgid}")
  sku                     = "Basic"
  depends_on = [azurerm_resource_group.azuregoat]

}
data "azurerm_public_ip" "vm_ip" {
  name                = azurerm_public_ip.VM_PublicIP.name
  resource_group_name = var.resource_group
  depends_on          = [azurerm_virtual_machine.dev-vm]
}
#Network interface
resource "azurerm_network_interface" "net_int" {
  name                = "developerVMNetInt"
  location            = var.region
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vNet_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.VM_PublicIP.id
  }
  depends_on = [azurerm_resource_group.azuregoat, 
    azurerm_network_security_group.net_sg,
    azurerm_public_ip.VM_PublicIP,
    azurerm_subnet.vNet_subnet
  ]
}

#Network Interface SG allocation
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.net_int.id
  network_security_group_id = azurerm_network_security_group.net_sg.id
}


#Virtual Machine
resource "azurerm_virtual_machine" "dev-vm" {

  name                  = "developerVM${var.cgid}"
  location              = var.region
  resource_group_name   = var.resource_group
  network_interface_ids = [azurerm_network_interface.net_int.id]


  vm_size = "Standard_B1s"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  identity {
    type = "SystemAssigned"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "developerVMDisk"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "developerVM"
    admin_username = "azureuser"
    admin_password = "St0r95p@$sw0rd@1265463541"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  depends_on = [azurerm_resource_group.azuregoat, 
    azurerm_network_interface.net_int
  ]

}

resource "azurerm_virtual_machine_extension" "test" {
  name                 = "vm-extension"
  virtual_machine_id   = azurerm_virtual_machine.dev-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "script": "${base64encode(templatefile("../assets/resources/vm/config.sh", {
          URL="${azurerm_storage_account.storage_account.id}.blob.core.windows.net/${azurerm_storage_container.storage_container_prod.name}"
        }))}"
    }
SETTINGS
depends_on = [azurerm_resource_group.azuregoat, null_resource.file_replacement_upload,azurerm_storage_blob.app_files_prod]
}
