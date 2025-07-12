# ----------------------------
# main.tf
#
# This file sets up the scalable Kubernetes AI infrastructure using Terraform.
# It includes multi-master nodes, scalable worker nodes, MetalLB, Cilium CNI,
# and optional Ingress and Dashboard modules. 
# -----------------------------------------
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kubernetes-admin@k8s-cluster"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kubernetes-admin@k8s-cluster"
  }
}

module "masters" {
  for_each = {
    master1 = {
      ip_address  = "172.16.100.100"
      hostname    = "k8s-master-1"
      is_primary  = true
    }
    master2 = {
      ip_address  = "172.16.100.101"
      hostname    = "k8s-master-2"
      is_primary  = false
    }
  }

  source                 = "./modules/master-node"
  ip_address             = each.value.ip_address
  hostname               = each.value.hostname
  is_primary             = each.value.is_primary
  ssh_user               = var.ssh_user
  ssh_private_key        = var.ssh_private_key
  pod_cidr               = var.pod_cidr
  network_plugin         = var.network_plugin
  control_plane_endpoint = var.control_plane_endpoint
}


# -----------------------------------------
# Scalable Worker Nodes
# -----------------------------------------
module "workers" {
  for_each             = var.worker_nodes
  source               = "./modules/worker-node"
  hostname             = each.value.hostname
  ip_address           = each.value.ip_address
  ssh_user             = var.ssh_user
  ssh_private_key      = var.ssh_private_key
  kubeadm_join_command = module.masters["master1"].kubeadm_join_command
  depends_on           = [module.masters]
}

# -----------------------------------------
# MetalLB Load Balancer Module
# -----------------------------------------
module "metallb" {
  source     = "./modules/metallb"
  depends_on = [module.masters]
}

# -----------------------------------------
# Cilium CNI Module
# -----------------------------------------
module "cilium" {
  source = "./modules/cilium"
}

# -----------------------------------------
# Ingress Module (NGINX + Dashboard exposure)
# -----------------------------------------
module "ingress" {
  source            = "./modules/ingress"
  cilium_dependency = module.cilium
}

# -----------------------------------------
# Kubernetes Dashboard Module (Optional)
# -----------------------------------------
module "dashboard" {
  source             = "./modules/dashboard"
  depends_on         = [module.cilium]
  cilium_dependency  = module.cilium
  ingress_dependency = module.ingress
}
