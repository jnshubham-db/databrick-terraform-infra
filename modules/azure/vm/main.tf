resource "azurerm_network_interface" "this" {
  count = try(var.config.enabled, true) ? 1 : 0

  name                = "${var.config.name}-nic"
  location            = var.config.location
  resource_group_name = var.config.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.config.subnet_id
    private_ip_address_allocation = try(var.config.private_ip_address_allocation, "Dynamic")
    private_ip_address            = try(var.config.private_ip_address, null)
    public_ip_address_id          = try(var.config.public_ip_address_id, null)
  }

  tags = try(var.config.tags, {})
}

resource "azurerm_linux_virtual_machine" "this" {
  count = try(var.config.enabled, true) && try(var.config.os_type, "linux") == "linux" ? 1 : 0

  name                = var.config.name
  resource_group_name = var.config.resource_group_name
  location            = var.config.location
  size                = var.config.vm_size
  admin_username      = var.config.admin_username

  network_interface_ids = [
    azurerm_network_interface.this[0].id,
  ]

  admin_ssh_key {
    username   = var.config.admin_username
    public_key = try(var.config.admin_ssh_public_key, file("~/.ssh/id_rsa.pub"))
  }

  disable_password_authentication = try(var.config.disable_password_authentication, true)

  os_disk {
    caching              = try(var.config.os_disk.caching, "ReadWrite")
    storage_account_type = try(var.config.os_disk.storage_account_type, "Standard_LRS")
    disk_size_gb         = try(var.config.os_disk.disk_size_gb, null)
  }

  source_image_reference {
    publisher = try(var.config.source_image_reference.publisher, "Canonical")
    offer     = try(var.config.source_image_reference.offer, "0001-com-ubuntu-server-jammy")
    sku       = try(var.config.source_image_reference.sku, "22_04-lts-gen2")
    version   = try(var.config.source_image_reference.version, "latest")
  }

  tags = try(var.config.tags, {})
}

resource "azurerm_windows_virtual_machine" "this" {
  count = try(var.config.enabled, true) && try(var.config.os_type, "linux") == "windows" ? 1 : 0

  name                = var.config.name
  resource_group_name = var.config.resource_group_name
  location            = var.config.location
  size                = var.config.vm_size
  admin_username      = var.config.admin_username
  admin_password      = var.config.admin_password

  network_interface_ids = [
    azurerm_network_interface.this[0].id,
  ]

  os_disk {
    caching              = try(var.config.os_disk.caching, "ReadWrite")
    storage_account_type = try(var.config.os_disk.storage_account_type, "Standard_LRS")
    disk_size_gb         = try(var.config.os_disk.disk_size_gb, null)
  }

  source_image_reference {
    publisher = try(var.config.source_image_reference.publisher, "MicrosoftWindowsServer")
    offer     = try(var.config.source_image_reference.offer, "WindowsServer")
    sku       = try(var.config.source_image_reference.sku, "2022-Datacenter")
    version   = try(var.config.source_image_reference.version, "latest")
  }

  tags = try(var.config.tags, {})
}

