output "worker_ips" {
  value       = [for k, v in var.hosts : v.ip if v.role == "worker"]
  description = "IP addresses of worker nodes"
}

output "control_plane_ips" {
  value       = [for k, v in var.hosts : v.ip if v.role == "control"]
  description = "IP addresses of control plane nodes"
}
