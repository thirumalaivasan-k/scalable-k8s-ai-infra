# HCP Terraform Workspace Configuration Guide

## Workspace Setup

### 1. Create Workspace
1. Log into HCP Terraform: https://app.terraform.io/
2. Navigate to your organization
3. Click **New Workspace** → **CLI-driven workflow**
4. Name: `scalable-k8s-onprem` (or your preferred name)
5. Optionally set a working directory if repo has multiple configs

### 2. Configure Workspace Settings

**General Settings:**
- Execution Mode: **Remote** (runs on HCP infrastructure)
- Terraform Version: `>= 1.5.0`
- Auto Apply: **Disabled** (require manual approval for safety)

**Version Control (Optional):**
- Connect to GitHub repository for automatic plan triggers
- Branch: `main`
- Working Directory: `terraform/onprem`

### 3. Set Sensitive Variables

Navigate to workspace → **Variables** → Add variable:

#### SSH Private Key (HCL)
- **Variable name:** `ssh_private_keys`
- **Type:** Terraform variable
- **HCL:** ✅ Checked
- **Sensitive:** ✅ Checked
- **Value:**
```hcl
{
  default = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
NhAAAAAwEAAQAAAYEA... (your full private key)
...
-----END OPENSSH PRIVATE KEY-----
EOT
}
```

#### Join Command (String)
- **Variable name:** `kube_join_command`
- **Type:** Terraform variable
- **Sensitive:** ✅ Checked
- **Value:**
```
kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

### 4. Optional Non-Sensitive Variables

You can also set these in HCP (or keep in local `terraform.tfvars`):

- `kubernetes_version`: `1.29.3-00`
- `http_proxy`: (if needed)
- `https_proxy`: (if needed)

### 5. Local WSL Configuration

**Backend Configuration:**
Create `backend.tf` in `terraform/onprem/`:
```hcl
terraform {
  cloud {
    organization = "your-org-name"
    workspaces {
      name = "scalable-k8s-onprem"
    }
  }
}
```

**Authenticate:**
```bash
terraform login
```

**Initialize:**
```bash
cd terraform/onprem
terraform init
```

Output should show:
```
Terraform Cloud has been successfully initialized!
```

### 6. Running Plans and Applies

**Plan:**
```bash
terraform plan
```
- HCP Terraform streams output to your terminal
- Sensitive values are redacted in logs

**Apply:**
```bash
terraform apply
```
- Review plan summary
- Type `yes` to confirm
- Monitor progress in terminal or HCP UI

### 7. Workspace State Management

**View State:**
- HCP UI → Workspace → States
- Encrypted at rest by default
- Versioned with rollback capability

**Lock State:**
- Automatic during runs
- Prevents concurrent modifications

## Security Best Practices

✅ **Enable MFA** on your HCP Terraform account
✅ **Use Team Permissions** to restrict who can apply changes
✅ **Enable Audit Logging** (Enterprise) for compliance
✅ **Rotate Tokens** regularly (kubeadm and HCP API tokens)
✅ **Use Sentinel Policies** to enforce security guardrails
✅ **Review Run History** for unexpected changes

## Troubleshooting

**Error: "Connection timeout"**
- Verify nodes are reachable from HCP runners (check firewall rules)
- Consider using Terraform Agent on-prem for private network access

**Error: "Invalid private key"**
- Ensure HCL formatting is correct with `<<-EOT` heredoc syntax
- Check for extra newlines or spaces
- Verify key permissions on source machine

**Error: "Token expired"**
- Kubeadm tokens are valid for 24h
- Regenerate with `kubeadm token create --print-join-command`
- Update HCP variable

**Terraform Agent for Private Networks:**
If nodes are not publicly accessible:
1. Install Terraform Agent in your network (VM or container)
2. Configure workspace to use Agent Pool
3. Agent proxies execution from HCP to private resources

## Next Steps

1. Test with a single worker node first
2. Verify idempotency by running `terraform apply` multiple times
3. Add nodes incrementally
4. Implement backup strategy for state (HCP handles this automatically)
5. Set up monitoring and alerting for infrastructure changes
