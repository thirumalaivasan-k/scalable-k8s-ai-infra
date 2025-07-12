# ----------------------------
# modules/ingress/variables.tf
# ----------------------------

variable "namespace" {
  description = "Namespace for NGINX ingress controller"
  type        = string
  default     = "ingress-nginx"
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
