
# ----------------------------
# modules/ingress/outputs.tf
# ----------------------------

output "nginx_release_name" {
  value       = helm_release.nginx_ingress.name
  description = "Helm release name of NGINX ingress"
}

output "nginx_namespace" {
  value       = helm_release.nginx_ingress.namespace
  description = "Namespace where NGINX ingress is deployed"
}

output "nginx_status" {
  value       = helm_release.nginx_ingress.status
  description = "Deployment status of the NGINX ingress controller"
}
