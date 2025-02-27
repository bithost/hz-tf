terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.44.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "k0s_network" {
  name     = "k0s-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k0s_subnet" {
  network_id   = hcloud_network.k0s_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_firewall" "k0s_firewall" {
  name = "k0s-firewall"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Kubernetes API
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # k0s API
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Konnectivity
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8132"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Allow all internal traffic
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [hcloud_network.k0s_network.ip_range]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [hcloud_network.k0s_network.ip_range]
  }

  # ICMP (ping)
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "controller" {
  name         = "k0s-controller"
  image        = "ubuntu-22.04"
  server_type  = var.server_type_controller
  location     = var.location
  ssh_keys     = [var.ssh_key]
  firewall_ids = [hcloud_firewall.k0s_firewall.id]
  labels = {
    role = "controller"
  }
  
  depends_on = [hcloud_network_subnet.k0s_subnet]
  
  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y curl jq net-tools"
    ]
  }
}

resource "hcloud_server_network" "controller_network" {
  server_id = hcloud_server.controller.id
  subnet_id = hcloud_network_subnet.k0s_subnet.id
  ip        = "10.0.1.10"
}

resource "hcloud_server" "worker" {
  count        = 2
  name         = "k0s-worker-${count.index + 1}"
  image        = "ubuntu-22.04"
  server_type  = var.server_type_worker
  location     = var.location
  ssh_keys     = [var.ssh_key]
  firewall_ids = [hcloud_firewall.k0s_firewall.id]
  labels = {
    role = "worker"
  }
  
  depends_on = [hcloud_network_subnet.k0s_subnet]
  
  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y curl jq net-tools"
    ]
  }
}

resource "hcloud_server_network" "worker_network" {
  count     = 2
  server_id = hcloud_server.worker[count.index].id
  subnet_id = hcloud_network_subnet.k0s_subnet.id
  ip        = "10.0.1.${count.index + 20}"
}

# Load Balancer Configuration
resource "hcloud_load_balancer" "k0s_load_balancer" {
  name               = "k0s-load-balancer"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_network" "load_balancer_network" {
  load_balancer_id = hcloud_load_balancer.k0s_load_balancer.id
  subnet_id        = hcloud_network_subnet.k0s_subnet.id
  ip               = "10.0.1.100"
}

# Target the controller node with the label selector
resource "hcloud_load_balancer_target" "load_balancer_target" {
  type             = "server"
  load_balancer_id = hcloud_load_balancer.k0s_load_balancer.id
  server_id        = hcloud_server.controller.id
}

# Configure Load Balancer Services
resource "hcloud_load_balancer_service" "load_balancer_service_6443" {
  load_balancer_id = hcloud_load_balancer.k0s_load_balancer.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "load_balancer_service_9443" {
  load_balancer_id = hcloud_load_balancer.k0s_load_balancer.id
  protocol         = "tcp"
  listen_port      = 9443
  destination_port = 9443
}

resource "hcloud_load_balancer_service" "load_balancer_service_8132" {
  load_balancer_id = hcloud_load_balancer.k0s_load_balancer.id
  protocol         = "tcp"
  listen_port      = 8132
  destination_port = 8132
}