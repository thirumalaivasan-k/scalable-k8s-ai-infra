output "kubernetes_dashboard_release_name" {
  value       = helm_release.kubernetes_dashboard.name
  description = "Release name of the Kubernetes Dashboard"
}

output "kubernetes_dashboard_namespace" {
  value       = helm_release.kubernetes_dashboard.namespace
  description = "Namespace where Kubernetes Dashboard is deployed"
}

output "kubernetes_dashboard_status" {
  value       = helm_release.kubernetes_dashboard.status
  description = "Status of the Kubernetes Dashboard release"
}
