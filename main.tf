output "timestamp" {
    value = formatdate("MM-DD-YYYY", timestamp())
}

resource "azurerm_resource_group" "rgname" {
    name = lower("${var.user_identifier}-poc-${var.customername}")
    location = var.location
    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_network_security_group" "nsg" {
    name = lower("${var.customername}-nsg")
    location = azurerm_resource_group.rgname.location
    resource_group_name = azurerm_resource_group.rgname.name

    security_rule {
        name = "Allow-HTTPS"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "443"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "Allow-SSH"
        priority = 101
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "Allow-Intra"
        priority = 102
        direction = "Inbound"
        access = "Allow"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "Default-Deny"
        priority = 200
        direction = "Inbound"
        access = "Deny"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_public_ip" "firewallip" {
    name = lower("${var.customername}-panfwmgmt")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    allocation_method = "Dynamic"

    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_public_ip" "panormaip" {
    name = lower("${var.customername}-panorama")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    allocation_method = "Dynamic"

    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_storage_account" "poc" {
    name = lower("${var.customername}diag")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    public_network_access_enabled = "false"
    blob_properties {
      delete_retention_policy {
        days = 7
      }
    }
    queue_properties {
      logging {
        delete = true
        read = true
        write = true
        version = "1.0"
        retention_policy_days = 10
      }
    }

    network_rules {
      default_action="Deny"
    }

    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_storage_account" "blob" {
    name = lower("${var.customername}blob")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    public_network_access_enabled = "false"
    account_kind = "BlobStorage"
    blob_properties {
      delete_retention_policy {
        days = 7
      }
    }

    network_rules {
      default_action="Deny"
    }

    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_route_table" "internal" {
    name = "internal_routetable"
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location

    route {
        name = "default"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "VirtualAppliance"
        next_hop_in_ip_address = "100.64.2.4"
    }
    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_route_table" "external" {
    name = "external_routetable"
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location

    route {
        name = "default"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "Internet"
    }
    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
}

resource "azurerm_virtual_network" "vnet" {
    name = lower("${var.customername}-vnet")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    address_space = ["100.64.0.0/24","100.64.1.0/24","100.64.2.0/24"]

    tags = {
        function = "VNET"
    }
}

resource "azurerm_subnet" "Mgmt" {
    name = "Mgmt"
    resource_group_name = azurerm_resource_group.rgname.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["100.64.0.0/24"]
    depends_on = [
      azurerm_virtual_network.vnet
    ]
}

resource "azurerm_subnet" "Untrust" {
  name = "Untrust"
  resource_group_name = azurerm_resource_group.rgname.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["100.64.1.0/24"]
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet" "Trust" {
    name = "Trust"
    resource_group_name = azurerm_resource_group.rgname.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = [ "100.64.2.0/24" ]
    depends_on = [
      azurerm_virtual_network.vnet
    ]
}

resource "azurerm_subnet_route_table_association" "Trust" {
    subnet_id = azurerm_subnet.Trust.id
    route_table_id = azurerm_route_table.internal.id
    depends_on = [
      azurerm_subnet.Trust,
      azurerm_route_table.internal
    ]
}

resource "azurerm_subnet_route_table_association" "Untrust" {
  subnet_id = azurerm_subnet.Untrust.id
  route_table_id = azurerm_route_table.external.id
  depends_on = [
    azurerm_subnet.Untrust,
    azurerm_route_table.external
  ]
}

resource "azurerm_subnet_network_security_group_association" "Mgmt" {
  subnet_id = azurerm_subnet.Mgmt.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_subnet.Mgmt,
    azurerm_network_security_group.nsg
  ]
}


resource "azurerm_subnet_network_security_group_association" "NSGTrust" {
  subnet_id = azurerm_subnet.Trust.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_subnet.Trust,
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_subnet_network_security_group_association" "NSGUntrust" {
  subnet_id = azurerm_subnet.Untrust.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_subnet.Untrust,
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_network_interface" "fw-eth0" {
  name = "fw-eth0"
  resource_group_name = azurerm_resource_group.rgname.name
  location = azurerm_resource_group.rgname.location

  ip_configuration {
    name = "ipconfig_mgmt"
    subnet_id = azurerm_subnet.Mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address = "100.64.0.4"
    primary = true
    public_ip_address_id = azurerm_public_ip.firewallip.id
  }
  tags = {
    function = "FW-MGMT"
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.Mgmt,
    azurerm_public_ip.firewallip
  ]
}

resource "azurerm_network_interface" "fw-eth1" {
  name = "fw-eth1"
  resource_group_name = azurerm_resource_group.rgname.name
  location = azurerm_resource_group.rgname.location
  enable_ip_forwarding = true 
  enable_accelerated_networking = true

  ip_configuration {
   name = "ipconfig_untrust"
   subnet_id = azurerm_subnet.Untrust.id
   private_ip_address_allocation = "Static"
   private_ip_address = "100.64.1.4"
   public_ip_address_id = azurerm_public_ip.panormaip.id  
  }
  tags = {
    function = "FW-UNTRUST"
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.NSGUntrust,
    azurerm_public_ip.panormaip
  ]
}

resource "azurerm_network_interface" "fw-eth2" {
    name = "fw-eth2"
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    enable_ip_forwarding = true 
    enable_accelerated_networking = true 

    ip_configuration {
      name = "ipconfig_trust"
      subnet_id = azurerm_subnet.Trust.id
      private_ip_address_allocation = "Static"
      private_ip_address = "100.64.2.4"
    }
    tags = {
        function = "FW-Trust"
    }
    depends_on = [
      azurerm_subnet_network_security_group_association.NSGTrust
    ]
}

resource "azurerm_network_interface" "panorama-mgmt" {
    name = "panorama-mgmt"
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    enable_ip_forwarding = false 
    enable_accelerated_networking = false

    ip_configuration {
      name = "ipconfig_panorama"
      subnet_id = azurerm_subnet.Trust.id
      private_ip_address_allocation = "Static"
      private_ip_address = "100.64.2.5"
    }
    tags = {
        function = "Panorama-MGMT"
    }
    depends_on = [
      azurerm_subnet_network_security_group_association.NSGTrust
    ]
}

resource "azurerm_network_interface_security_group_association" "fw-eth0" {
  network_interface_id = azurerm_network_interface.fw-eth0.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
  azurerm_subnet_network_security_group_association.Mgmt
]
}

resource "azurerm_network_interface_security_group_association" "fw-eth1" {
  network_interface_id = azurerm_network_interface.fw-eth1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
  azurerm_subnet_network_security_group_association.NSGUntrust
  ]
}

resource "azurerm_network_interface_security_group_association" "fw-eth2" {
  network_interface_id = azurerm_network_interface.fw-eth2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
  azurerm_subnet_network_security_group_association.NSGTrust
  ]
}

resource "azurerm_network_interface_security_group_association" "panorama-mgmt" {
  network_interface_id = azurerm_network_interface.panorama-mgmt.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [
    azurerm_subnet_network_security_group_association.NSGTrust
  ]
}

resource "azurerm_virtual_machine" "NGFW" {
    name = lower("${var.customername}-ngfw")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    vm_size = "Standard_DS3_v2"
    plan {
        name = "byol"
        publisher = "paloaltonetworks"
        product = "vmseries-flex"
    }
    storage_image_reference {
      publisher = "paloaltonetworks"
      offer = "vmseries-flex"
      sku = "byol"
      version = "${var.firewall_version}" 
    }
    storage_os_disk {
      name = lower("${var.customername}-ngfw-osdisk")
      vhd_uri = "${azurerm_storage_account.poc.primary_blob_endpoint}vhds/${var.customername}-ngfw-osdisk1.vhd"
      caching = "Readonly"
      create_option = "FromImage"
    }
    os_profile {
      computer_name = lower("${var.customername}-ngfw")
      admin_username = var.admin_username
      admin_password = var.admin_password
    }
    primary_network_interface_id = azurerm_network_interface.fw-eth0.id
    network_interface_ids =   [azurerm_network_interface.fw-eth0.id,
                                        azurerm_network_interface.fw-eth1.id,
                                        azurerm_network_interface.fw-eth2.id]
    os_profile_linux_config {
      disable_password_authentication = false
    }

    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
    depends_on = [
      azurerm_network_interface_security_group_association.fw-eth0,
      azurerm_network_interface_security_group_association.fw-eth1,
      azurerm_network_interface_security_group_association.fw-eth2
    ]
}

resource "azurerm_virtual_machine" "panorama" {
    name = lower("${var.customername}-panorama")
    resource_group_name = azurerm_resource_group.rgname.name
    location = azurerm_resource_group.rgname.location
    vm_size = "Standard_D4_v2"
    plan {
        name = "byol"
        publisher = "paloaltonetworks"
        product = "panorama"
    }
    storage_image_reference {
        publisher = "paloaltonetworks"
        offer = "panorama"
        sku = "byol"
        version = "${var.panorama_version}"
    }
    storage_os_disk {
        name = lower("${var.customername}-panorama-osdisk")
        vhd_uri = "${azurerm_storage_account.poc.primary_blob_endpoint}vhds/${var.customername}-panorama-osdisk1.vhd"
        caching = "Readonly"
        create_option = "FromImage"
    }
    os_profile {
        computer_name = lower("${var.customername}-panorama")
        admin_username = var.admin_username
        admin_password = var.admin_password
    }
    primary_network_interface_id = azurerm_network_interface.panorama-mgmt.id
    network_interface_ids = [azurerm_network_interface.panorama-mgmt.id]

    os_profile_linux_config {
      disable_password_authentication = false
    }
    tags = {
        StoreStatus = "DND"
        RunStatus = "NOSTOP"
        no-shut-contact = "${var.SE_Email}"
    }
    depends_on = [
      azurerm_network_interface.panorama-mgmt
    ]
}

# Read the Route53 Zone into the dataset

# data "aws_route53_zone" "prisma" {
#  zone_id = "Z04208933C23Y6NDNWXFB"
#}

# Read the Public IP's

data "azurerm_public_ip" "panoramaip" {
    name = azurerm_public_ip.panormaip.name
    resource_group_name = azurerm_resource_group.rgname.name
    depends_on = [
      azurerm_virtual_machine.NGFW
    ]
}

data "azurerm_public_ip" "firewallip" {
    name = azurerm_public_ip.firewallip.name
    resource_group_name = azurerm_resource_group.rgname.name
    depends_on = [
      azurerm_virtual_machine.NGFW
    ]
}

#resource "aws_route53_record" "panorama" {
#  zone_id = data.aws_route53_zone.prisma.zone_id
#  name = lower("${var.customername}.prisma-poc.com")
#  type = "A"
#  ttl = "300"
#  records = [data.azurerm_public_ip.panoramaip.ip_address]
#  depends_on = [
#    azurerm_virtual_machine.NGFW
#  ]
#}

#resource "aws_route53_record" "ngfw" {
#  zone_id = data.aws_route53_zone.prisma.zone_id
#  name = lower("${var.customername}-fw.prisma-poc.com")
#  type = "A"
#  ttl = "300"
#  records = [data.azurerm_public_ip.firewallip.ip_address]
#  depends_on = [
#    azurerm_virtual_machine.NGFW
#  ]
#}


# Export Terraform Variable values to an Ansible vars.file
resource "local_file" "tf_ansible_vars_file_new" {
  content = <<-DOC
    # Ansible vars_file containing variable values from the Terraform plan
    # Generated by Terraform configration

    ngfwip: ${data.azurerm_public_ip.firewallip.ip_address}
    panoramaip: ${data.azurerm_public_ip.panoramaip.ip_address}
    admin_username: ${var.admin_username}
    admin_password: ${var.admin_password}
    certpassphrase: ${var.cert_passphrase}
    certurl: ${var.cert_url}
    timezone: ${var.timezone}
    customername: ${var.customername}
    serial_number: ${var.panorama_sn}
    DOC
  filename = "./tf_ansible_vars_file.yml"
  depends_on = [
    aws_route53_record.ngfw
  ]
}


resource "null_resource" "ansible-playbook" {
  provisioner "local-exec" {
    command = "ansible-playbook /Ansible_poc_automation-docker/Config.yml --extra-vars '@tf_ansible_vars_file.yml'"
  }
  depends_on = [
    local_file.tf_ansible_vars_file_new
  ]
}

resource "null_resource" "BestPractice" {
  provisioner "local-exec" {
    command = "ansible-playbook /Ansible_poc_automation-docker/BestPractice.yml --extra-vars '@tf_ansible_vars_file.yml"
  }
  depends_on = [
    null_resource.ansible-playbook
  ]
}

output "ngfw_public_ip" {
    value = data.azurerm_public_ip.firewallip.ip_address
}

output "panorama_public_ip" {
    value = data.azurerm_public_ip.panoramaip.ip_address
}