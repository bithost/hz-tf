output "controller_ip" {
  description = "Public IP address of the controller node"
  value       = hcloud_server.controller.ipv4_address
}

output "controller_private_ip" {
  description = "Private IP address of the controller node"
  value       = hcloud_server_network.controller_network.ip
}

output "worker_ips" {
  description = "Public IP addresses of the worker nodes"
  value       = [for worker in hcloud_server.worker : worker.ipv4_address]
}

output "worker_private_ips" {
  description = "Private IP addresses of the worker nodes"
  value       = [for i, worker in hcloud_server.worker : hcloud_server_network.worker_network[i].ip]
}

output "loadbalancer_ip" {
  description = "Public IP address of the load balancer"
  value       = hcloud_load_balancer.k0s_load_balancer.ipv4
}

output "network_id" {
  description = "ID of the Hetzner network"
  value       = hcloud_network.k0s_network.id
}

output "k0s_connection_string" {
  description = "Connection string for accessing the k0s cluster"
  value       = "https://${hcloud_load_balancer.k0s_load_balancer.ipv4}:6443"
}