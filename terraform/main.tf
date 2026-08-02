
provider "proxmox" {
  endpoint  = "https://192.168.1.131:8006/api2/json"
  api_token = var.proxmox_api_token
  insecure  = true
}



#Добавляются ВМ

locals {
  vms = {
    nginx-1 = {
      vm_id = 201
      ip    = "192.168.1.201/24"
      cpu   = 2
      ram   = 2048
      disk  = 10
      role  = "nginx"
    }
    nginx-2 = {
      vm_id = 202
      ip    = "192.168.1.202/24"
      cpu   = 2
      ram   = 2048
      disk  = 10
      role  = "nginx"
    }
    backend-1 = {
      vm_id    = 211
      ip       = "192.168.1.211/24"
      cpu      = 2
      ram      = 2048
      disk     = 10
      role     = "backend"
      iscsi_ip = "10.10.40.11/24"
    }
    backend-2 = {
      vm_id    = 212
      ip       = "192.168.1.212/24"
      cpu      = 2
      ram      = 2048
      disk     = 10
      role     = "backend"
      iscsi_ip = "10.10.40.12/24"
    }
    db-1 = {
      vm_id = 221
      ip    = "192.168.1.221/24"
      cpu   = 2
      ram   = 2048
      disk  = 10
      role  = "db"
    }
    db-2 = {
      vm_id = 222
      ip    = "192.168.1.222/24"
      cpu   = 2
      ram   = 2048
      disk  = 10
      role  = "db"
    }
    db-3 = {
      vm_id = 223
      ip    = "192.168.1.223/24"
      cpu   = 2
      ram   = 2048
      disk  = 10
      role  = "db"
    }
    storage-1 = {
      vm_id    = 231
      ip       = "192.168.1.231/24"
      cpu      = 2
      ram      = 2048
      disk     = 20
      role     = "storage"
      iscsi_ip = "10.10.40.21/24"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each      = local.vms
  name          = each.key
  node_name     = var.proxmox_node
  vm_id         = each.value.vm_id
  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id        = var.template_vm_id
    full         = true
    datastore_id = var.vm_datastore
  }

  description = "Managed by Terraform: ${each.value.role}"

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = var.vm_bridge
    model  = "virtio"
  }

  dynamic "network_device" {
    for_each = try(each.value.iscsi_ip, null) != null ? [1] : []
    content {
      bridge = var.iscsi_bridge
      model  = "virtio"
    }
  }

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = each.value.disk
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  initialization {
    datastore_id = var.cloudinit_datastore

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = var.vm_gateway
      }
    }
    dynamic "ip_config" {
      for_each = try(each.value.iscsi_ip, null) != null ? [1] : []
      content {
        ipv4 {
          address = each.value.iscsi_ip
        }
      }
    }
    user_account {
      username = var.vm_user
      keys     = [trimspace(file(var.ssh_public_key_path))]
    }

    dns {
      servers = var.vm_dns_servers
    }
  }

  operating_system {
    type = "l26"
  }

  on_boot = true
  started = true
}


# Дополнительные диски для backend-нод-----------------------------------------





# OUTPUTS   -------------------------------------------------------------

output "nginx_1_ip" {
  value = split("/", local.vms["nginx-1"].ip)[0]
}

output "nginx_2_ip" {
  value = split("/", local.vms["nginx-2"].ip)[0]
}

output "backend_1_ip" {
  value = split("/", local.vms["backend-1"].ip)[0]
}

output "backend_2_ip" {
  value = split("/", local.vms["backend-2"].ip)[0]
}

output "db_1_ip" {
  value = split("/", local.vms["db-1"].ip)[0]
}


output "db_2_ip" {
  value = split("/", local.vms["db-2"].ip)[0]
}


output "db_3_ip" {
  value = split("/", local.vms["db-3"].ip)[0]
}

output "vip_nginx" {
  value = "192.168.1.203"
}


output "storage_1_ip" {
  value = split("/", local.vms["storage-1"].ip)[0]
}

output "storage_1_iscsi_ip" {
  value = split("/", local.vms["storage-1"].iscsi_ip)[0]
}


