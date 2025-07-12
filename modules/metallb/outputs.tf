# ----------------------------
# modules/metallb/outputs.tf
# ----------------------------

output "metallb_release_name" {
  value       = helm_release.metallb.name
  description = "The name of the MetalLB Helm release"
}

output "metallb_namespace" {
  value       = helm_release.metallb.namespace
  description = "The namespace where MetalLB is installed"
}

output "metallb_version" {
  value       = helm_release.metallb.version
  description = "The version of the MetalLB Helm chart installed"
}
