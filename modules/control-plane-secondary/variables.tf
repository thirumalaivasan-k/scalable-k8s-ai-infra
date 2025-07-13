
# modules/control-plane-secondary/variables.tf

variable "ip_address" {
  description = "IP address of the secondary control plane node"
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private key for access"
  type        = string
  sensitive   = true
}

variable "join_command_script_path" {
  description = "Path to join-command.sh script from primary control plane"
  type        = string
}
