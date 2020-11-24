provider "azurerm" {
  features {}
}
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
  
  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.10.10.0/24"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Subnet
resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.10.0/29"]
}

# Network Security groups with rules
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "${var.prefix}-nsgrule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
        name                       = "${var.prefix}-nsgruledisallowinternet"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-loadbalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-ft_PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# NSG & Subnet Association
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-backEndAddressPool"
}

# NIC and Backend Address Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count					          = var.vmcount
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "${var.prefix}-nicinternalipconfig-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# Network Interface - NIC
resource "azurerm_network_interface" "main" { 
  count               = var.vmcount
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  ip_configuration {
    name                          = "${var.prefix}-nicinternalipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Availibility Set
resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-availabilityset"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Managed Disks
resource "azurerm_managed_disk" "main" {
  count                = var.vmcount
  name                 = "${var.prefix}_datadisk_existing_${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vmcount
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  availability_set_id             = azurerm_availability_set.main.id
  #network_interface_ids           = ["${element(azurerm_network_interface.main.*.id, count.index)}"]
  network_interface_ids           = [element(azurerm_network_interface.main.*.id, count.index)]
  computer_name                   = "${var.prefix}vm${count.index}"

  source_image_id                 = var.vmimage

  os_disk {
    name                 = "${var.prefix}-osdisk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    tagenv = "${var.prefix}-Project1"
  }
}

# VMs and Managed disk attachments
resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count				       = var.vmcount
  managed_disk_id    = azurerm_managed_disk.main.*.id[count.index]
  virtual_machine_id = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}