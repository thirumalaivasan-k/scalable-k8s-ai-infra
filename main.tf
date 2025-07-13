# ----------------------------
# main.tf
#
# This file sets up the scalable Kubernetes AI infrastructure using Terraform.
# It includes multi-master nodes, scalable worker nodes, MetalLB, Cilium CNI,
# and optional Ingress and Dashboard modules. 

# ----------------------------
# Root Module: main.tf
# ----------------------------
locals {
  control_plane_endpoint = "${var.primary_master.ip_address}:6443"
}
# Primary Control Plane (first master)
module "control_plane_primary" {
  source                 = "./modules/control-plane-primary"
  hostname               = var.primary_master.hostname
  ip_address             = var.primary_master.ip_address
  ssh_user               = var.ssh_user
  ssh_private_key        = var.ssh_private_key
  control_plane_endpoint = local.control_plane_endpoint
  pod_cidr               = var.pod_cidr
  network_plugin         = var.network_plugin
}

# Secondary Control Plane Nodes (master2, master3)
module "control_plane_secondary" {
  for_each               = var.master_nodes
  source                 = "./modules/control-plane-secondary"
  ip_address             = each.value.ip_address
  ssh_user               = var.ssh_user
  ssh_private_key        = var.ssh_private_key
  join_command_script_path = "${path.module}/modules/control-plane-primary/join-command.sh"
}

# Worker Nodes
module "worker_node" {
  for_each               = var.worker_nodes
  source                 = "./modules/worker-node"
  ip_address             = each.value.ip_address
  ssh_user               = var.ssh_user
  ssh_private_key        = var.ssh_private_key
  join_command_script_path = "${path.module}/modules/control-plane-primary/join-command.sh"
}

