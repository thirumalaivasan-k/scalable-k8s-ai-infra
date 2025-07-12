
# ----------------------------
# modules/master-node/outputs.tf
# ----------------------------

output "master_node_ip" {
  value       = var.ip_address
  description = "IP address of the master node"
}

output "hostname" {
  value       = var.hostname
  description = "Hostname of the master node"
}

data "local_file" "join_command_file" {
  count    = var.is_primary ? 1 : 0
  filename = "${path.module}/join-command.sh"
}

output "kubeadm_join_command" {
  value       = var.is_primary ? chomp(trimspace(data.local_file.join_command_file[0].content)) : null
  description = "Join command for worker and other master nodes"
}
output "control_plane_endpoint" {
  value       = var.control_plane_endpoint
  description = "Shared control plane endpoint for the cluster"
}
