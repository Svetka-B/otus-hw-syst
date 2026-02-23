resource "yandex_vpc_network" "hw3_net" {
  name = "otus"
}

resource "yandex_vpc_subnet" "test_subnet" {
  v4_cidr_blocks = ["10.2.0.0/16"]
  network_id     = yandex_vpc_network.hw3_net.id
}

resource "yandex_vpc_address" "test-addr" {
  name = "exampleAddress"

  external_ipv4_address {
    zone_id = var.zone
  }
}

resource "yandex_compute_disk" "boot_disk" {
  name     = "boot-disk"
  zone     = var.zone
  image_id = var.image_ubuntu_2404
  size     = 15
}

resource "yandex_compute_instance" "ubuntu" {
  name                      = "ubuntu-vm"
  allow_stopping_for_update = true
  platform_id               = var.standart

  resources {
    cores  = "2"
    memory = "2"
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk.id
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.test_subnet.id
    nat            = true
    nat_ip_address = yandex_vpc_address.test-addr.external_ipv4_address.0.address
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.sshkeyspath)}"
  }
}