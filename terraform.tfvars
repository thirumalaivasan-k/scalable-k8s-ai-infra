ssh_user        = "webadmin"
ssh_private_key = "~/.ssh/id_rsa"
pod_cidr        = "10.244.0.0/16"
network_plugin  = "cilium"

master_nodes = {
  master1 = {
    hostname               = "k8s-master1"
    ip_address             = "172.16.100.100"
    control_plane_endpoint = "https://k8s-master1:6443"
    is_primary             = true // This is the primary master node should only one master primary at a time
  }
  master2 = {
    hostname               = "k8s-master2"
    ip_address             = "172.16.100.101"
    control_plane_endpoint = "https://k8s-master2:6443"
    is_primary             = false
  }
}


worker_nodes = {
  worker1 = {
    hostname   = "k8s-worker-01"
    ip_address = "172.16.100.110"
  }
  worker2 = {
    hostname   = "k8s-worker-02"
    ip_address = "172.16.100.111"
  }
  worker3 = {
    hostname   = "k8s-worker-03"
    ip_address = "172.16.100.112"
  }
}
