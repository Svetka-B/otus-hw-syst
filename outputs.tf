output "internal_ip_address_vm" {
  description = "internal IP-адрес виртуальной машины"
  value       = yandex_compute_instance.ubuntu.network_interface.0.ip_address
}

output "external_ip_address_vm" {
  description = "external IP-адрес виртуальной машины"
  value       = yandex_compute_instance.ubuntu.network_interface.0.nat_ip_address
}
