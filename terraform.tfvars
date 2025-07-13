# ----------------------------
# terraform.tfvars
#
# This file sets up the scalable Kubernetes AI infrastructure using Terraform.
# 

# ----------------------------
# Root Module: terraform.tfvars
# ----------------------------

ssh_user        = "webadmin"
ssh_private_key = "~/.ssh/id_rsa"
pod_cidr        = "10.244.0.0/16"
network_plugin  = "cilium"

primary_master = {
  hostname   = "k8s-master"
  ip_address = "172.16.100.100"
}

master_nodes = {
  master2 = {
    hostname   = "k8s-master2"
    ip_address = "172.16.100.101"
  }
  master3 = {
    hostname   = "k8s-master3"
    ip_address = "172.16.100.102"
  }
}

worker_nodes = {
  worker1 = {
    hostname   = "k8s-worker1"
    ip_address = "172.16.100.110"
  }
  worker2 = {
    hostname   = "k8s-worker2"
    ip_address = "172.16.100.111"
  }
  worker3 = {
    hostname   = "k8s-worker3"
    ip_address = "172.16.100.112"
  }
}
