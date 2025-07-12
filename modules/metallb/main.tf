# ----------------------------
# modules/metallb/main.tf
# ----------------------------

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = "metallb-system"
  version    = "0.14.3"

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]
}
