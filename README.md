# Scalable Kubernetes AI Infrastructure

Terraform automation for provisioning and managing on-premises Kubernetes clusters via SSH, integrated with HCP Terraform for secure secret management and remote execution. Designed for AI/ML workloads requiring scalable, reproducible infrastructure.

## 🚀 Quick Start

**New to this project?** Start here:
1. Read [QUICKSTART.md](terraform/onprem/QUICKSTART.md) - Step-by-step setup guide
2. Review [ARCHITECTURE.md](terraform/onprem/ARCHITECTURE.md) - Understand the system design
3. Configure [HCP_SETUP.md](terraform/onprem/HCP_SETUP.md) - Set up HCP Terraform workspace

**Already configured?** Deploy in 3 commands:
```bash
cd terraform/onprem
terraform init
terraform apply
```

## 📋 What's Included

- **Terraform Configuration** (`terraform/onprem/`): SSH-based provisioning for Ubuntu servers
- **Bootstrap Scripts**: Automated installation of containerd, kubelet, kubeadm (following official docs)
- **HCP Integration**: Secure storage of SSH keys and join tokens in HCP Terraform
- **WSL Support**: Full workflow runs in Windows Subsystem for Linux
- **Documentation**: Comprehensive guides for setup, operation, and troubleshooting

## 🎯 Use Case

You have:
- ✅ Existing Ubuntu 22.04 LTS servers (physical or VM)
- ✅ SSH access to these servers
- ✅ A Kubernetes control plane (existing or to be created)
- ✅ Need to join workers to the cluster reproducibly

This solution provides:
- 🔐 Secure credential management via HCP Terraform
- 🔄 Idempotent provisioning (safe to re-run)
- 📊 Terraform state management (versioned, encrypted)
- 🪟 WSL integration for Linux tooling on Windows
- 📚 Production-ready patterns following Kubernetes official documentation

## Terraform On-Prem Node Preparation

Path: `terraform/onprem`

Goal: Use Terraform to remotely configure Ubuntu nodes through SSH to be Kubernetes-ready (swap disabled, containerd installed, kube packages installed). Optionally join workers to an already running control plane cluster when a `kubeadm join` command is provided.

### Architecture Overview
- **Terraform Agent**: Runs in WSL (Windows Subsystem for Linux) with HCP Terraform integration
- **Sensitive Data**: Stored securely in HCP Terraform workspace variables (SSH keys, join commands, optional control-plane join command)
- **Node Provisioning**: SSH-based remote-exec to existing Ubuntu servers
- **Cluster Access**: kubectl configured in WSL using admin.conf from control plane
- **HA Support**: Optional second (or more) control-plane nodes using `control_plane_join_command`

### When to Use This Pattern
Use this if:
- You already have physical/VM Ubuntu servers reachable via SSH.
- You have (or will create) a Kubernetes control plane separately (e.g., an existing cluster or cloud-based control plane).
- You want reproducible node prep captured in Terraform state.
- You're using HCP Terraform for secure secret management and remote execution.

Consider using a configuration management tool (e.g., Ansible) for more granular lifecycle management; Terraform provisioners suit initial bootstrap, not ongoing drift correction.

### Files Overview
- `variables.tf` – Input variables including host inventory, single SSH private key, worker join command, control-plane join command.
- `main.tf` – `null_resource` blocks executing scripts over SSH; supports local scripts or remote URL download.
- `outputs.tf` – Exposes control plane and worker IPs.
- `terraform.tfvars.example` – Non-sensitive variable template; copy to `terraform.tfvars` and customize.
- `.gitignore` – Prevents committing state files, tfvars, and sensitive keys.
- `scripts/install_prereqs.sh` – Performs kubeadm official setup steps (containerd, kubelet, etc.).
- `scripts/kube_node_join.sh` – Executes supplied `kubeadm join` safely (idempotent).
- `scripts/run_prereqs.tftpl` – Template wrapper exporting variables before running prereqs.

### 🔐 Sensitive Variable Strategy (HCP Terraform)

**Store as SENSITIVE in HCP Terraform workspace variables:**
1. `ssh_private_keys` (type: map(string))
   ```hcl
   ssh_private_keys = {
     default = "-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----"
   }
   ```
   - Used for SSH provisioning to all nodes
   - Mark as **Sensitive** in HCP UI
   - Never commit to Git

2. `kube_join_command` (type: string)
   ```bash
   kubeadm join 192.168.1.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
   ```
   - Full join command including token and CA cert hash
   - Mark as **Sensitive** in HCP UI
   - Rotate when token expires (default 24h)

3. `control_plane_join_command` (type: string)
  - Used only for additional control-plane nodes (HA)
  - Includes `--control-plane --certificate-key <key>` parameters
  - Certificate key generated via: `kubeadm init phase upload-certs --upload-certs`

**Repo-Safe Variables (in terraform.tfvars):**
- `hosts`: Map of Ubuntu nodes with IP and role (user optional; falls back to `ssh_user`)
- `kubernetes_version`: Optional version pin (e.g., "1.29.3-00")
- `install_containerd_version`: Optional containerd version
- `http_proxy`, `https_proxy`, `no_proxy`: Optional network proxy settings
- `script_url`: Optional URL to hosted k8s-prepare.sh script

**Setting Variables in HCP Terraform:**
1. Navigate to workspace → Variables
2. Add `ssh_private_keys` with HCL syntax, check **Sensitive**
3. Add `kube_join_command` as string, check **Sensitive**
4. Terraform Agent will securely inject these during remote runs

### Prerequisites
On the control plane (already existing cluster or to be created):
1. Prepare control plane per official kubeadm docs (Ubuntu):
	 ```bash
	 swapoff -a
	 # install containerd + kube packages (same steps as script)
	 kubeadm init --pod-network-cidr=192.168.0.0/16
	 ```
2. Configure kubectl:
	 ```bash
	 mkdir -p $HOME/.kube
	 sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
	 sudo chown $(id -u):$(id -g) $HOME/.kube/config
	 ```
3. Install a CNI (example Calico):
	 ```bash
	 kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
	 ```
4. Generate worker join command (token valid for 24h by default):
	 ```bash
	 kubeadm token create --print-join-command
	 ```
	 Copy the full output (starts with `kubeadm join ...`). Provide it to Terraform as `kube_join_command` variable.

If you need the CA cert hash separately:
```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
	openssl rsa -pubin -outform der 2>/dev/null | \
	openssl dgst -sha256 -hex | sed 's/^.* //' 
```

### WSL + Terraform Agent Setup

**Install Terraform in WSL:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Configure HCP Terraform CLI:**
```bash
terraform login
# Follow prompts to authenticate with HCP Terraform
```

**Clone repo and navigate:**
```bash
cd /home/<your-user>/scalable-k8s-ai-infra/terraform/onprem
```

### Defining Host Inventory
Copy example and customize `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Example content:
```hcl
hosts = {
  control1 = {
    ip       = "192.168.1.10"
    user     = "ubuntu"
    key_name = "default"
    role     = "control"
  }
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

kubernetes_version = "1.29.3-00"
# script_url = "https://raw.githubusercontent.com/your-org/scripts/main/k8s-prepare.sh"
```

**Note:** `key_name = "default"` references the key in `ssh_private_keys["default"]` stored in HCP Terraform.### Running Terraform
From WSL terminal in `terraform/onprem`:
```bash
terraform init
terraform plan
terraform apply
```

HCP Terraform will:
1. Securely inject `ssh_private_keys` and `kube_join_command` from workspace variables
2. SSH into each node using the mapped private key
3. Run prerequisite installation script (containerd, kubelet, kubeadm)
4. Execute `kubeadm join` on worker nodes (if join command provided)
5. Output configured host IPs

### Configuring kubectl in WSL

After Terraform completes and control plane is initialized, copy admin.conf from control node to WSL:

**From WSL:**
```bash
# Replace with your control plane IP and user
scp ubuntu@192.168.1.10:/etc/kubernetes/admin.conf ~/admin.conf

# Set up kubectl config
mkdir -p ~/.kube
mv ~/admin.conf ~/.kube/config
chmod 600 ~/.kube/config

# Verify cluster access
kubectl get nodes
kubectl get pods -A
```

**Expected output:**
```
NAME       STATUS   ROLES           AGE   VERSION
control1   Ready    control-plane   10m   v1.29.3
worker1    Ready    <none>          5m    v1.29.3
worker2    Ready    <none>          5m    v1.29.3
```

**Security Note:**
- This grants **full cluster admin access** from WSL
- Only use on trusted machines
- For shared access, generate scoped kubeconfigs with RBAC:
  ```bash
  kubectl create serviceaccount limited-user
  kubectl create clusterrolebinding limited-user --clusterrole=view --serviceaccount=default:limited-user
  kubectl create token limited-user --duration=8760h
  ```

### Idempotency Notes
- Script creates `/etc/kubernetes/prepared`; re-running skips prerequisite steps.
- Join script checks for existing `/etc/kubernetes/kubelet.conf` to avoid duplicate join attempts.
- Updating `kube_join_command` changes the null_resource trigger and will attempt join again on workers not yet joined.

### Rotating Join Token
Kubeadm tokens expire after 24 hours by default. To refresh:

**On control plane node:**
```bash
kubeadm token create --print-join-command
```

**Update HCP Terraform:**
1. Navigate to workspace → Variables
2. Update `kube_join_command` with new output
3. Run `terraform apply` from WSL

Only workers not yet joined will execute the new worker join command (idempotency checks in place). For additional control-plane nodes, update `control_plane_join_command` similarly if tokens or certificate key rotate.

### Adding More Workers
Add entries under `hosts` with `role = "worker"` then `terraform apply`. New nodes will prepare and join automatically if `kube_join_command` is still valid.

### Limitations
- Terraform provisioners are best-effort; failures may require `terraform taint null_resource.prepare_nodes["worker1"]` then re-apply.
- Ongoing config drift (e.g., package upgrades) is not managed; use Ansible or another CM tool for lifecycle.
- Control plane initialization is intentionally manual to keep state consistent and avoid embedding secrets in Terraform state.

### Best Practices for HCP Terraform + WSL

**Security:**
- ✅ Never commit `terraform.tfvars` with sensitive data
- ✅ Always mark SSH keys and join commands as **Sensitive** in HCP
- ✅ Rotate join tokens regularly (use long-lived bootstrap tokens for automation)
- ✅ Restrict admin.conf access; generate scoped kubeconfigs for developers
- ✅ Use SSH key passphrases and store them in WSL keychain

**Workflow:**
- ✅ Use WSL for Linux-native SSH and kubectl workflows
- ✅ Keep Terraform state in HCP Terraform (automatic encryption at rest)
- ✅ Version your infrastructure code in Git (without secrets)
- ✅ Use HCP Terraform workspaces per environment (dev/staging/prod)
- ✅ Enable Sentinel policies in HCP for compliance guardrails

**Modularity:**
- ✅ Extract common logic into reusable Terraform modules
- ✅ Use `script_url` to centralize maintenance of bootstrap scripts
- ✅ Parameterize everything (versions, CIDRs, node counts)
- ✅ Document variable constraints and validation rules

**Operations:**
- ✅ Test in isolated environment before production
- ✅ Use `terraform plan` to preview changes
- ✅ Tag infrastructure resources with workspace/environment metadata
- ✅ Monitor HCP Terraform run logs for provisioning failures
- ✅ Implement backup strategy for etcd and persistent volumes

### Next Enhancements (Planned)
- Automate capturing join command: remote-exec on control plane to generate and export as output.
- Optional module to install a CNI (Calico/Cilium/Flannel).
- Integration with HCP Vault for dynamic SSH credential generation.
- HCP Consul agent deployment for service mesh and discovery.
- Multi-control-plane (HA) setup with load balancer.
- Automated backup of etcd to S3/Azure Blob.

## References
- Kubernetes kubeadm docs: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- Containerd docs: https://containerd.io/
- Terraform Provisioners: https://developer.hashicorp.com/terraform/language/resources/provisioners
- HCP Terraform: https://developer.hashicorp.com/terraform/cloud-docs
- WSL Documentation: https://learn.microsoft.com/en-us/windows/wsl/

## HCP Integration (Outline)
If using HashiCorp Cloud Platform (e.g., Vault, Consul) with agents on-prem:
- Install agents separately (system packages or manual). Terraform could distribute agent config via additional provisioners.
- Use Vault Agent for automatic token renewal and write Kubernetes secrets to files consumed by workloads.
- Register nodes in Consul for service discovery if running services outside Kubernetes.

Future code examples will live under `terraform/hcp`.
