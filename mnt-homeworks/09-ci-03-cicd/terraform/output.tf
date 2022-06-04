#Output

output "external_ip_address_sonar_01" {
  value = yandex_compute_instance.sonar-01.network_interface.0.nat_ip_address
}

output "external_ip_address_nexus_01" {
  value = yandex_compute_instance.nexus-01.network_interface.0.nat_ip_address
}
