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

resource "yandex_vpc_network" "yollard-vpc" {
  name = "yollard-vpc"
}

resource "yandex_vpc_route_table" "private_rt" {
  network_id = yandex_vpc_network.yollard-vpc.id
  name       = "private-rt"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "10.1.0.10"
  }
}

resource "yandex_vpc_subnet" "yollard-vpc-subnet" {
  name           = "yollard-vpc-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.yollard-vpc.id
  v4_cidr_blocks = ["10.2.0.0/16"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.yollard-vpc.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_compute_instance" "vm-1-angie" {
  name = "vm-1-angie"

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
    ip_address = "10.1.0.10"
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"

    user-data = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - iptables
        - iptables-persistent

      write_files:
        - path: /usr/local/sbin/configure-nat.sh
          permissions: '0755'
          content: |
            #!/bin/bash
            set -eux

            sysctl -w net.ipv4.ip_forward=1
            sed -i '/^net.ipv4.ip_forward/d' /etc/sysctl.conf
            echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

            iptables -t nat -C POSTROUTING -s 10.2.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || \
            iptables -t nat -A POSTROUTING -s 10.2.0.0/16 -o eth0 -j MASQUERADE

            netfilter-persistent save
      runcmd:
        - /usr/local/sbin/configure-nat.sh
    EOF
  }

  scheduling_policy {
    preemptible = false
  }
}

resource "yandex_compute_instance" "vm-2-front1" {
  name = "vm-2-front1"

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
    subnet_id = yandex_vpc_subnet.yollard-vpc-subnet.id
    nat       = false
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

resource "yandex_compute_instance" "vm-3-front2" {
  name = "vm-3-front2"

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
    subnet_id = yandex_vpc_subnet.yollard-vpc-subnet.id
    nat       = false
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

resource "yandex_compute_instance" "vm-4-back1" {
  name = "vm-4-back1"

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
    subnet_id = yandex_vpc_subnet.yollard-vpc-subnet.id
    nat       = false
  }

  metadata = {
    ssh-keys           = "ubuntu:${file(var.sshkeyspath)}"
    serial-port-enable = "0"
  }
}

output "vm_1_public_ip" {
  value = yandex_compute_instance.vm-1-angie.network_interface.0.nat_ip_address
}

output "vm_1_private_ip" {
  value = yandex_compute_instance.vm-1-angie.network_interface.0.ip_address
}

output "vm_2_private_ip" {
  value = yandex_compute_instance.vm-2-front1.network_interface.0.ip_address
}

output "vm_3_private_ip" {
  value = yandex_compute_instance.vm-3-front2.network_interface.0.ip_address
}

output "vm_4_private_ip" {
  value = yandex_compute_instance.vm-4-back1.network_interface.0.ip_address
}