# High Availability example: two control planes + workers
# Sensitive values (ssh_private_key, control_plane_join_command, kube_join_command) must be set in HCP Terraform variables.

ssh_user = "ubuntu"

hosts = {
  control-primary = {
    ip   = "172.16.100.100"
    role = "control"
  }
  control-secondary = {
    ip   = "172.16.100.101"
    role = "control"
  }
  worker1 = {
    ip   = "172.16.0.110"
    role = "worker"
  }
  worker2 = {
    ip   = "172.16.0.111"
    role = "worker"
  }
  # Add more workers incrementally
}

# Optional version pins
kubernetes_version         = "1.29.3-00"
install_containerd_version = ""

# Network proxy (optional)
http_proxy  = ""
https_proxy = ""
no_proxy    = "localhost,127.0.0.1,172.16.0.0/16"

# script_url can point to a remote bootstrap script; leave blank to use local scripts
script_url = ""

# Sensitive (set in HCP Terraform workspace):
# ssh_private_key                = "-----BEGIN OPENSSH PRIVATE KEY-----..."
# control_plane_join_command     = "kubeadm join 172.16.100.100:6443 --token <t> --discovery-token-ca-cert-hash sha256:<h> --control-plane --certificate-key <certkey>"
# kube_join_command              = "kubeadm join 172.16.100.100:6443 --token <t> --discovery-token-ca-cert-hash sha256:<h>"
