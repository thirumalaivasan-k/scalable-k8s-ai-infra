resource "helm_release" "kubernetes_dashboard" {
  name             = "kubernetes-dashboard"
  namespace        = var.namespace
  repository       = "https://kubernetes.github.io/dashboard/"
  chart            = "kubernetes-dashboard"
  version          = var.chart_version
  create_namespace = true

  values = [
    file("${path.module}/kubernetes-dashboard-values.yaml")
  ]

  depends_on = [
    var.cilium_dependency,
    var.ingress_dependency
  ]
}

data "kubernetes_secret" "dashboard_token" {
  metadata {
    name      = "kubernetes-dashboard-token"
    namespace = helm_release.kubernetes_dashboard.namespace
  }

  depends_on = [helm_release.kubernetes_dashboard]
}

output "kubernetes_dashboard_token" {
  value       = data.kubernetes_secret.dashboard_token.data["token"]
  sensitive   = true
  description = "Token to access Kubernetes Dashboard"
}

