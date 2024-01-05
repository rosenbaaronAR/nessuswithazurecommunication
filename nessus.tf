### Used to create a random passwor${var.name}nessd ###
resource "random_string" "nessus" {
  length           = 16
  special          = true
  min_special      = 2
  override_special = "*!@#?"
}

## Setup the Virtual Network ###


resource "azurerm_virtual_network" "nessus" {

  name                = "nessus-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["8.8.8.8", "1.1.1.1"]
  subnet {
    name           = "nessus-subnet"
    address_prefix = "10.0.1.0/24"

  }

}

### Provision a static public IP address

resource "azurerm_public_ip" "nessus" {
  name                = "nessus-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"


}
### Create an NSG to allow inbound access to both web interfaces and restric SSH access to specific IP addresses

resource "azurerm_network_security_group" "nessuspub" {
  name                = "nessus-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "nessus-webinterface"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8834"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "nessus-system_web_interface"
    priority                   = 1020
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Inbound"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "8000"
  }
  security_rule {
    name                       = "nessus-ssh"
    priority                   = 1030
    protocol                   = "Tcp"
    access                     = "Allow"
    direction                  = "Inbound"
    source_port_range          = "*"
    source_address_prefixes    = ["192.168.1.1"] ### Change this to your public IP address to limit access
    destination_address_prefix = "*"
    destination_port_range     = "22"
  }


}

### Create a public network interface 

resource "azurerm_network_interface" "nessus-pub" {
  name                = "nessus-pubnic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "nessus-ipconfig1"
    subnet_id                     = azurerm_virtual_network.nessus.subnet.*.id[0]
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.nessus.id
  }



}

### Associate the NSG to the network interface

resource "azurerm_network_interface_security_group_association" "nessus-pub" {

  depends_on                = [azurerm_network_interface.nessus-pub]
  network_interface_id      = azurerm_network_interface.nessus-pub.id
  network_security_group_id = azurerm_network_security_group.nessuspub.id


}
/*
resource "azurerm_marketplace_agreement" "nessus" {

  publisher = var.publisher
  offer = var.offer
  plan = "nessus"
  
  
}
*/

### Creates the Virtual Machine ###

resource "azurerm_virtual_machine" "nessus" {

  name                             = "nessus-vm"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  network_interface_ids            = [azurerm_network_interface.nessus-pub.id]
  primary_network_interface_id     = azurerm_network_interface.nessus-pub.id
  vm_size                          = "Standard_B2ms"
  delete_data_disks_on_termination = true
  storage_image_reference {
    publisher = "tenable"
    offer     = "tenablecorenessus"
    sku       = "tenablecoreol8nessusbyol"
    version   = "latest"
  }

  plan {
    name      = "tenablecoreol8nessusbyol"
    publisher = "tenable"
    product   = "tenablecorenessus"

  }
  storage_os_disk {
    name              = "nessus-oskdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }


  os_profile {
    computer_name  = "nessus-vm"
    admin_username = "nessus-admin"
    admin_password = random_string.nessus.result

  }
  os_profile_linux_config {

    disable_password_authentication = false
  }


}


output "public_ip" {

  value = azurerm_public_ip.nessus.ip_address

}