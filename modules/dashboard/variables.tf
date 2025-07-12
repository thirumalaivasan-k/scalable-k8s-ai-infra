# ----------------------------
# modules/ingress/variables.tf
# ----------------------------

variable "namespace" {
  description = "Namespace for NGINX ingress controller"
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Helm chart version for NGINX ingress controller"
  type        = string
  default     = "4.10.0"
}

variable "cilium_dependency" {
  description = "Dependency on the Cilium module"
  type        = any
}
# Add your variable declarations here

variable "ingress_dependency" {
  description = "Dependency to ensure ingress is created before the dashboard"
  type        = any
}
variable "dashboard_namespace" {
  description = "Namespace where the dashboard is deployed"
  type        = string
  default     = "kube-system"
}
