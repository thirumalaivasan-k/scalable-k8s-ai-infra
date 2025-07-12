// Root outputs
output "master_node_ips" {
  description = "List of master node IPs"
  value       = [for m in var.master_nodes : m.ip_address]
}

output "worker_node_ips" {
  description = "List of worker node IPs"
  value       = [for w in var.worker_nodes : w.ip_address]
}

output "cni_plugin" {
  description = "The network plugin used"
  value       = var.network_plugin
}
output "pod_cidr" {
  description = "The Pod CIDR for the cluster"
  value       = var.pod_cidr
}
