#Output
output "internal_ip_address_nat-vm" {
  value = yandex_compute_instance.nat-vm-1.network_interface.0.ip_address
}
output "external_ip_address_nat-vm" {
  value = yandex_compute_instance.nat-vm-1.network_interface.0.nat_ip_address
}

output "internal_ip_address_public-vm-1" {
  value = yandex_compute_instance.public-vm-1.network_interface.0.ip_address
}
output "external_ip_address_public-vm-1" {
  value = yandex_compute_instance.public-vm-1.network_interface.0.nat_ip_address
}

output "internal_ip_address_private-vm-1" {
  value = yandex_compute_instance.private-vm-1.network_interface.0.ip_address
}
output "external_ip_address_private-vm-1" {
  value = yandex_compute_instance.private-vm-1.network_interface.0.nat_ip_address
}