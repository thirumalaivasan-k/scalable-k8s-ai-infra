# ----------------------------
# modules/worker-node/variables.tf
# ----------------------------

variable "hostname" {
  type        = string
  description = "Hostname of the worker node"
}

variable "ip_address" {
  type        = string
  description = "IP address of the worker node"
}

variable "ssh_user" {
  type        = string
  description = "SSH user"
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key path"
}

variable "kubeadm_join_command" {
  type        = string
  description = "Kubeadm join command"
}
