terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloudid
  folder_id = var.folderid
  zone      = var.zone
}

resource "yandex_vpc_network" "yollard_vpc" {
  name = "yollard_vpc"
}

resource "yandex_vpc_gateway" "natgw" {
  name = "natgw"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "private_rt"
  network_id = yandex_vpc_network.yollard_vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.natgw.id
  }
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public_subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.yollard_vpc.id
  v4_cidr_blocks = ["10.2.0.0/24"]
}

resource "yandex_vpc_subnet" "internal_subnet" {
  name           = "internal_subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.yollard_vpc.id
  v4_cidr_blocks = ["10.1.0.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# Дополнительные диски для backend-нод-----------------------------------------
resource "yandex_compute_disk" "backend_1_gfs_disk" {
  name = "backend-1-gfs-disk"
  type = "network-hdd"
  size = 10
}

resource "yandex_compute_disk" "backend_2_gfs_disk" {
  name = "backend-2-gfs-disk"
  type = "network-hdd"
  size = 10
}

# Добавляются ВМ --------------------------------------------------------------

resource "yandex_compute_instance" "nginx_1" {
  name = "nginx_1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_ubuntu
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public_subnet.id
    nat        = true
    ip_address = "10.2.0.10"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.internal_subnet.id
    nat        = false
    ip_address = "10.1.0.10"
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }

  scheduling_policy {
    preemptible = false
  }
}

resource "yandex_compute_instance" "nginx_2" {
  name = "nginx_2"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_ubuntu
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public_subnet.id
    nat        = true
    ip_address = "10.2.0.11"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.internal_subnet.id
    nat        = false
    ip_address = "10.1.0.11"
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

resource "yandex_compute_instance" "backend_1" {
  name                      = "backend_1"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_ubuntu
      size     = 10
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.backend_1_gfs_disk.id
    auto_delete = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.internal_subnet.id
    nat        = false
    ip_address = "10.1.0.21"
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

resource "yandex_compute_instance" "backend_2" {
  name                      = "backend_2"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_ubuntu
      size     = 10
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.backend_2_gfs_disk.id
    auto_delete = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.internal_subnet.id
    nat        = false
    ip_address = "10.1.0.22"
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

resource "yandex_compute_instance" "database_1" {
  name = "database_1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_ubuntu
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.internal_subnet.id
    nat        = false
    ip_address = "10.1.0.31"
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

# Добавляется NLB -------------------------------------------------------------

resource "yandex_lb_network_load_balancer" "nlb_1" {
  name = "nlb-1"

  listener {
    name = "listener-1"
    port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg_1.id

    healthcheck {
      name = "http"

      http_options {
        port = 80
        path = "/ping"
      }
    }
  }
}

resource "yandex_lb_target_group" "tg_1" {
  name      = "tg-1"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    address   = yandex_compute_instance.nginx_1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    address   = yandex_compute_instance.nginx_2.network_interface.0.ip_address
  }
}

output "nginx_1_public_ip" {
  value = yandex_compute_instance.nginx_1.network_interface.0.nat_ip_address
}

output "nginx_2_public_ip" {
  value = yandex_compute_instance.nginx_2.network_interface.0.nat_ip_address
}

output "nginx_1_internal_ip" {
  value = yandex_compute_instance.nginx_1.network_interface.1.ip_address
}

output "nginx_2_internal_ip" {
  value = yandex_compute_instance.nginx_2.network_interface.1.ip_address
}

output "backend_1_private_ip" {
  value = yandex_compute_instance.backend_1.network_interface.0.ip_address
}

output "backend_2_private_ip" {
  value = yandex_compute_instance.backend_2.network_interface.0.ip_address
}

output "database_1_private_ip" {
  value = yandex_compute_instance.database_1.network_interface.0.ip_address
}

output "nlb_public_ip" {
  value = yandex_lb_network_load_balancer.nlb_1.listener.*.external_address_spec[0].*.address
}