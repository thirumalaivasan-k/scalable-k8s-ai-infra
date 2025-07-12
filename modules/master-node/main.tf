# ----------------------------
# modules/master-node/main.tf
# ----------------------------

resource "null_resource" "init_master" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    host        = var.ip_address
  }

  provisioner "remote-exec" {
    inline = var.is_primary ? [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",

      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",

      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",

      "sudo kubeadm init --control-plane-endpoint=${var.control_plane_endpoint} --pod-network-cidr=${var.pod_cidr} --apiserver-advertise-address=${var.ip_address}",

      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",

      "[ \"${var.network_plugin}\" = \"flannel\" ] && kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml || true"
      ] : [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",

      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",

      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",

      "sudo kubeadm join ${var.control_plane_endpoint} --token ${var.join_token} --discovery-token-ca-cert-hash ${var.discovery_hash} --control-plane --apiserver-advertise-address=${var.ip_address}"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "generate_join_command" {
  count = var.is_primary ? 1 : 0

  depends_on = [null_resource.init_master]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    host        = var.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "kubeadm token create --print-join-command > ~/join-command.sh"
    ]
  }

  provisioner "file" {
    source      = "~/join-command.sh"
    destination = "${path.module}/join-command.sh"
  }
}
