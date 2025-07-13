# modules/control-plane-primary/main.tf

resource "null_resource" "init_primary_master" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_private_key
    host        = var.ip_address
  }

  provisioner "file" {
    source      = "${path.module}/cilium-values.yaml"
    destination = "/tmp/cilium-values.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/metallb-values.yaml"
    destination = "/tmp/metallb-values.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab",

      # Install deps
      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",

      # Add Kubernetes repo
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",

      "sudo apt-get update -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",

      # Initialize cluster
      "sudo kubeadm init --control-plane-endpoint='${var.control_plane_endpoint}' --pod-network-cidr='${var.pod_cidr}' --apiserver-advertise-address='${var.ip_address}'",

      # Setup kubeconfig
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",

      # Install Helm
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",

      # Install Cilium CNI using values.yaml
      "helm repo add cilium https://helm.cilium.io/",
      "helm repo update",
      "helm install cilium cilium/cilium --version 1.14.5 --namespace kube-system -f /tmp/cilium-values.yaml",

      # Install MetalLB using Helm
      "helm repo add metallb https://metallb.github.io/metallb",
      "helm repo update",
      "helm install metallb metallb/metallb --namespace metallb-system --create-namespace",

      # Wait for MetalLB pods
      "sleep 30",

      # Apply MetalLB config
      "kubectl apply -f /tmp/metallb-values.yaml"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "generate_join_command" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_private_key
    host        = var.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "kubeadm token create > /tmp/kubeadm-token.txt",
      "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform DER 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > /tmp/ca-cert-hash.txt",

      "echo kubeadm join ${var.control_plane_endpoint} --token $(cat /tmp/kubeadm-token.txt) --discovery-token-ca-cert-hash $(cat /tmp/ca-cert-hash.txt) --control-plane --apiserver-advertise-address=${var.ip_address} > /tmp/join-command.sh",
      "chmod +x /tmp/join-command.sh"
    ]
  }

  depends_on = [null_resource.init_primary_master]

  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "fetch_join_command" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_private_key
    host        = var.ip_address
  }

  provisioner "file" {
    source      = "/tmp/join-command.sh"
    destination = "${path.module}/join-command.sh"
  }

  depends_on = [null_resource.generate_join_command]
}

data "local_file" "join_command" {
  filename   = "${path.module}/join-command.sh"
  depends_on = [null_resource.fetch_join_command]
}


