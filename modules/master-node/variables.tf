# ----------------------------
# modules/master-node/variables.tf
# ----------------------------

variable "hostname" {
  description = "Hostname of the master node"
  type        = string
}

variable "ip_address" {
  description = "IP address of the master node"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for connecting to the node"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH private key"
  type        = string
}

variable "pod_cidr" {
  description = "Pod CIDR range"
  type        = string
  default     = "10.244.0.0/16"
}

variable "network_plugin" {
  description = "CNI plugin (e.g., flannel, calico)"
  type        = string
  default     = "flannel"
}

variable "is_primary" {
  description = "Flag to determine if this is the primary master"
  type        = bool
}

variable "control_plane_endpoint" {
  description = "Shared control plane endpoint (e.g., LB IP or DNS name)"
  type        = string
}

variable "join_token" {
  description = "Join token for secondary control planes"
  type        = string
  default     = ""
}

variable "discovery_hash" {
  description = "Discovery token CA cert hash for secondary control planes"
  type        = string
  default     = ""
}
