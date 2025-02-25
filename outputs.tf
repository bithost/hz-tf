output "controller_ip" {
  description = "Public IP address of the controller node"
  value       = hcloud_server.controller.ipv4_address
}

output "controller_private_ip" {
  description = "Private IP address of the controller node"
  value       = hcloud_server.controller.network[0].ip
}

output "worker_ips" {
  description = "Public IP addresses of the worker nodes"
  value       = [for worker in hcloud_server.worker : worker.ipv4_address]
}

output "worker_private_ips" {
  description = "Private IP addresses of the worker nodes"
  value       = [for worker in hcloud_server.worker : worker.network[0].ip]
}

output "network_id" {
  description = "ID of the Hetzner network"
  value       = hcloud_network.k0s_network.id
}

output "k0s_connection_string" {
  description = "Connection string for accessing the k0s cluster"
  value       = "https://${hcloud_server.controller.ipv4_address}:6443"
}