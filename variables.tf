variable "ssh_user" {
  description = "The SSH user to access all nodes"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH private key"
  type        = string
}

variable "pod_cidr" {
  description = "Pod network CIDR for the cluster"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin to use (flannel, calico, cilium)"
  type        = string
}

variable "master_nodes" {
  description = "A map of master node definitions"
  type = map(object({
    hostname   = string
    ip_address = string
  }))
}

variable "worker_nodes" {
  description = "A map of worker node definitions"
  type = map(object({
    hostname   = string
    ip_address = string
  }))
}

variable "control_plane_endpoint" {
  description = "The shared endpoint for the Kubernetes control plane (e.g., load balancer IP or DNS)."
  type        = string
}
