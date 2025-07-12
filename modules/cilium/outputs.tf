output "cilium_chart_version" {
  value       = helm_release.cilium.version
  description = "Version of the Cilium chart deployed"
}

output "cilium_namespace" {
  value       = helm_release.cilium.namespace
  description = "Namespace where Cilium is deployed"
}

output "cilium_status" {
  value       = helm_release.cilium.status
  description = "Current status of the Cilium release"
}
