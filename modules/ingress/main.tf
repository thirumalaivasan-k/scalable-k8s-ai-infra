# ----------------------------
# modules/ingress/main.tf
# ----------------------------

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = var.namespace
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  create_namespace = true

  values = [
    file("${path.module}/nginx-ingress-values.yaml")
  ]

  depends_on = [
    var.cilium_dependency
  ]
}
