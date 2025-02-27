variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key" {
  description = "SSH Key Name in Hetzner Cloud"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "server_type_controller" {
  description = "Server type for controller node"
  type        = string
  default     = "cax11"
}

variable "server_type_worker" {
  description = "Server type for worker nodes"
  type        = string
  default     = "cax11"
}

variable "location" {
  description = "Hetzner location"
  type        = string
  default     = "nbg1"
}

variable "k0s_version" {
  description = "k0s version to install"
  type        = string
  default     = "v1.32.1+k0s.0"
}