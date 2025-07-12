resource "null_resource" "join_worker" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
    host        = var.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",

      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",

      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",

      "${var.kubeadm_join_command}"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}


