#Output
output "internal_ip_address_control-plane-vm" {
  value = [yandex_compute_instance.control-plane-vm.*.network_interface.0.ip_address]
}

output "external_ip_address_control-plane-vm" {
  value = [yandex_compute_instance.control-plane-vm.*.network_interface.0.nat_ip_address]
}

output "internal_ip_address_worker-node-vm" {
  value = [yandex_compute_instance.worker-node-vm.*.network_interface.0.ip_address]
}

output "external_ip_address_worker-node-vm" {
  value = [yandex_compute_instance.worker-node-vm.*.network_interface.0.nat_ip_address]
}