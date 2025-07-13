# ----------------------------
# modules/master-node/variables.tf
# ----------------------------

variable "hostname" {
  description = "Hostname of the primary master node"
  type        = string
}

variable "ip_address" {
  description = "IP address of the primary master node"
  type        = string
}

variable "ssh_user" {
  description = "Username to SSH into the nodes"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key for connecting to nodes"
  type        = string
  sensitive   = true
}

variable "control_plane_endpoint" {
  description = "Control plane endpoint to advertise"
  type        = string
}

variable "pod_cidr" {
  description = "Pod network CIDR block"
  type        = string
}

variable "network_plugin" {
  description = "CNI plugin (e.g., cilium)"
  type        = string
}
