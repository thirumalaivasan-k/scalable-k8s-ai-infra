# Quick Start Guide: On-Prem Kubernetes with Terraform + HCP + WSL

## Prerequisites Checklist
- [ ] Ubuntu 22.04 LTS servers (physical or VM) with SSH access
- [ ] HCP Terraform account (free tier available)
- [ ] Windows machine with WSL 2 installed agent installed 
- [ ] SSH key pair for server access
- [ ] One server designated as control plane (2 CPU, 2GB RAM minimum)
- [ ] Worker servers (2 CPU, 2GB RAM minimum each)
- [ ] Network connectivity between all nodes
- [ ] Sudo access on all servers

## Step 1: Prepare Control Plane (Manual)

SSH into your designated control plane node:
```bash
ssh ubuntu@<control-plane-ip>
```

Run these commands manually (or use the install_prereqs.sh script):
```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Load kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Install containerd and Kubernetes packages
sudo apt update
sudo apt install -y containerd kubelet kubeadm kubectl
sudo systemctl enable containerd kubelet

# Initialize control plane
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Generate join command for workers
kubeadm token create --print-join-command
```

**Save the join command output** - you'll need it for HCP Terraform.

## Step 2: Set Up WSL Environment

Open PowerShell as Administrator and install WSL:
```powershell
wsl --install -d Ubuntu-22.04
```

Once in WSL, install Terraform:
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform git -y

# Authenticate with HCP Terraform
terraform login
```

Clone this repository:
```bash
cd ~
git clone https://github.com/your-org/scalable-k8s-ai-infra.git
cd scalable-k8s-ai-infra/terraform/onprem
```

## Step 3: Configure HCP Terraform Workspace

1. Visit https://app.terraform.io/
2. Create organization (if first time)
3. Create new workspace: **scalable-k8s-onprem**
4. Choose **CLI-driven workflow**

Add sensitive variables (Settings → Variables):
- `ssh_private_keys` (HCL, Sensitive):
  ```hcl
  {
    default = <<-EOT
  -----BEGIN OPENSSH PRIVATE KEY-----
  <paste your private key here>
  -----END OPENSSH PRIVATE KEY-----
  EOT
  }
  ```
- `kube_join_command` (String, Sensitive):
  ```
  kubeadm join 192.168.1.10:6443 --token abc123... --discovery-token-ca-cert-hash sha256:def456...
  ```

## Step 4: Configure Local Variables

Create `backend.tf`:
```bash
cp backend.tf.example backend.tf
nano backend.tf
```

Update with your HCP org and workspace name.

Create `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Update with your server IPs:
```hcl
hosts = {
  worker1 = {
    ip       = "192.168.1.11"
    user     = "ubuntu"
    key_name = "default"
    role     = "worker"
  }
  worker2 = {
    ip       = "192.168.1.12"
    user     = "ubuntu"
    key_name = "default"
    role     = "worker"
  }
}
```

## Step 5: Run Terraform

Initialize:
```bash
terraform init
```

Review plan:
```bash
terraform plan
```

Apply configuration:
```bash
terraform apply
```

Type `yes` when prompted. Terraform will:
1. SSH into each worker node
2. Install containerd, kubelet, kubeadm
3. Execute kubeadm join command
4. Output configured IPs

## Step 6: Configure kubectl in WSL

Copy admin.conf from control plane:
```bash
scp ubuntu@<control-plane-ip>:/etc/kubernetes/admin.conf ~/.kube/config
chmod 600 ~/.kube/config
```

Verify cluster:
```bash
kubectl get nodes
kubectl get pods -A
```

Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
control1   Ready    control-plane   20m   v1.29.3
worker1    Ready    <none>          5m    v1.29.3
worker2    Ready    <none>          5m    v1.29.3
```

## Step 7: Test Deployment

Deploy a test application:
```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
```

Access nginx using any node IP and the assigned NodePort.

## Common Issues

**"Connection refused" during Terraform apply:**
- Verify SSH access manually: `ssh ubuntu@<node-ip>`
- Check firewall rules
- Ensure private key matches public key on nodes

**Nodes show NotReady:**
- Check CNI installation: `kubectl get pods -n kube-system | grep calico`
- Verify network connectivity between nodes
- Check kubelet logs: `journalctl -u kubelet`

**Token expired:**
- Regenerate: `kubeadm token create --print-join-command`
- Update `kube_join_command` in HCP Terraform
- Run `terraform apply` again

## Next Steps

- [ ] Deploy monitoring (Prometheus/Grafana)
- [ ] Set up ingress controller (Nginx/Traefik)
- [ ] Configure persistent storage (Longhorn/Rook)
- [ ] Implement backup strategy
- [ ] Add more worker nodes as needed
- [ ] Integrate with HCP Vault for secrets management
- [ ] Set up CI/CD pipelines

## Security Reminders

⚠️ **Admin kubeconfig grants full cluster access** - protect it carefully
⚠️ **Rotate kubeadm tokens regularly** (default expiry: 24h)
⚠️ **Use RBAC** to create limited-scope kubeconfigs for developers
⚠️ **Enable audit logging** in Kubernetes API server
⚠️ **Keep nodes updated** with security patches

## Resources

- Full documentation: `README.md`
- HCP setup guide: `HCP_SETUP.md`
- Kubernetes docs: https://kubernetes.io/docs/home/
- HCP Terraform: https://developer.hashicorp.com/terraform/cloud-docs
