#Output

output "external_ip_address_jenkins_master_01" {
  value = yandex_compute_instance.jenkins-master-01.network_interface.0.nat_ip_address
}

output "external_ip_address_jenkins_agent_01" {
  value = yandex_compute_instance.jenkins-agent-01.network_interface.0.nat_ip_address
}
