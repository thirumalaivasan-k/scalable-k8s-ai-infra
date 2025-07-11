# Architecture Overview: On-Prem Kubernetes with HCP Terraform

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HCP Terraform Cloud                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Workspace: scalable-k8s-onprem                           │  │
│  │                                                          │  │
│  │ Sensitive Variables (Encrypted):                        │  │
│  │  • ssh_private_keys (map)                               │  │
│  │  • kube_join_command (string)                           │  │
│  │                                                          │  │
│  │ State Management:                                       │  │
│  │  • Encrypted at rest                                    │  │
│  │  • Version controlled                                   │  │
│  │  • Team collaboration                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ TLS API
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                  Windows Workstation with WSL 2                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Ubuntu 22.04 (WSL)                                       │  │
│  │                                                          │  │
│  │  • Terraform CLI (logged in to HCP)                     │  │
│  │  • kubectl configured (~/.kube/config)                  │  │
│  │  • Git repository cloned                                │  │
│  │  • terraform/onprem/                                    │  │
│  │    ├── variables.tf                                     │  │
│  │    ├── main.tf                                          │  │
│  │    ├── terraform.tfvars (non-sensitive)                │  │
│  │    └── backend.tf (HCP config)                         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ SSH (provisioning)
                             │ kubectl (management)
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌────────────────┐   ┌────────────────┐   ┌──────────────────────────────┐
│ Control Plane  │   │ Control Plane  │   │        Worker Nodes           │
│ (Primary)      │   │ (Secondary)    │   │  (172.16.0.110 .. 172.16.0.n) │
│ Ubuntu 22.04    │   │ Ubuntu 22.04   │   │ Ubuntu 22.04                  │
│ Components:     │   │ Components:    │   │ Components:                   │
│ • etcd          │   │ • etcd         │   │ • kubelet                     │
│ • api-server    │   │ • api-server   │   │ • kube-proxy                  │
│ • scheduler     │   │ • scheduler    │   │ • containerd                  │
│ • controller    │   │ • controller   │   │ • (CNI pods)                  │
│ • kubelet       │   │ • kubelet      │   │ Status: Joined via kubeadm    │
│ • containerd    │   │ • containerd   │   │                               │
│ • CNI (Calico)  │   │ • CNI (Calico) │   │                               │
│ 172.16.100.100  │   │ 172.16.100.101 │   │ 172.16.0.110+                 │
└────────────────┘   └────────────────┘   └──────────────────────────────┘
```

## Data Flow

### 1. Initial Setup (One-Time)
```
Developer → HCP Terraform Web UI
  ↓
  1. Create workspace
  2. Set ssh_private_keys (Sensitive)
  3. Set kube_join_command (Sensitive)

Developer → WSL Terminal
  ↓
  1. terraform login (authenticate with HCP)
  2. Create backend.tf (workspace config)
  3. Create terraform.tfvars (node inventory)
```

### 2. Terraform Provisioning Flow
```
WSL: terraform apply
  ↓
  1. Load local tfvars (hosts, versions, etc.)
  2. Authenticate to HCP Terraform
  ↓
HCP Terraform
  ↓
  3. Merge HCP variables (ssh_private_keys, kube_join_command)
  4. Create execution plan
  5. Stream plan to WSL terminal
  ↓
WSL: Confirm apply
  ↓
HCP Terraform: Execute provisioners
  ↓
  6. For each worker node:
     a. SSH connect using private key
     b. Upload/download install_prereqs.sh
     c. Execute script (install containerd, kubelet, kubeadm)
     d. Execute kubeadm join command
     e. Verify join success
  ↓
  7. Update state (encrypted in HCP)
  8. Stream output to WSL (node IPs)
```

### 3. Cluster Management Flow
```
WSL: scp admin.conf from control plane
  ↓
  1. Copy /etc/kubernetes/admin.conf to ~/.kube/config
  2. Set permissions (chmod 600)
  ↓
WSL: kubectl get nodes
  ↓
  3. kubectl → Kubernetes API Server (control plane)
  4. API server authenticates using admin cert
  5. Returns cluster state
  ↓
WSL: Deploy applications
  ↓
  6. kubectl apply -f deployment.yaml
  7. Scheduler assigns pods to workers
  8. Kubelet on workers starts containers
```

## Security Architecture

### Secrets Management
```
┌─────────────────────────────────────────────────────────────┐
│ HCP Terraform (Encrypted at Rest)                           │
│                                                             │
│ ┌─────────────────────┐       ┌─────────────────────────┐ │
│ │ ssh_private_keys    │       │ kube_join_command       │ │
│ │ (map of SSH keys)   │       │ (with token + CA hash)  │ │
│ │                     │       │                         │ │
│ │ • Marked Sensitive  │       │ • Marked Sensitive      │ │
│ │ • Never in logs     │       │ • Never in logs         │ │
│ │ • Redacted in UI    │       │ • Redacted in UI        │ │
│ └─────────────────────┘       └─────────────────────────┘ │
└────────────────────┬──────────────────┬───────────────────┘
                     │                  │
         ┌───────────▼──────────────────▼──────────┐
         │ Injected into Terraform execution       │
         │ (memory only, never written to disk)    │
         └───────────┬──────────────────┬──────────┘
                     │                  │
              ┌──────▼──────┐    ┌──────▼──────┐
              │ SSH Session │    │ kubeadm join│
              │ (ephemeral) │    │ (one-time)  │
              └─────────────┘    └─────────────┘
```

### Network Security
```
┌─────────────────────────────────────────────────────────────┐
│ Firewall Rules (Recommended)                                │
├─────────────────────────────────────────────────────────────┤
│ Control Plane:                                              │
│  • TCP 6443  (Kubernetes API) ← WSL, Workers                │
│  • TCP 2379-2380 (etcd) ← Control Plane only                │
│  • TCP 10250 (kubelet) ← Control Plane, Workers             │
│  • TCP 10259 (kube-scheduler) ← localhost only              │
│  • TCP 10257 (kube-controller) ← localhost only             │
│  • TCP 22 (SSH) ← WSL (for provisioning)                    │
│                                                             │
│ Workers:                                                    │
│  • TCP 10250 (kubelet) ← Control Plane                      │
│  • TCP 30000-32767 (NodePort Services) ← Clients            │
│  • TCP 22 (SSH) ← WSL (for provisioning)                    │
│                                                             │
│ CNI (Calico):                                               │
│  • TCP 179 (BGP) ← All nodes                                │
│  • UDP 4789 (VXLAN) ← All nodes                             │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### HCP Terraform
- **State Storage**: Encrypted, versioned, team-accessible
- **Secret Management**: Sensitive variable injection
- **Execution**: Remote plan/apply with audit logs
- **Collaboration**: Team access controls, run approvals
- **Compliance**: Sentinel policy enforcement (Enterprise)

### WSL (Developer Workstation)
- **Development**: Edit Terraform configs, commit to Git
- **Authentication**: terraform login, kubectl authentication
- **Orchestration**: Trigger terraform plan/apply
- **Management**: kubectl commands to manage cluster
- **Monitoring**: View logs, troubleshoot issues

### Control Plane Node
- **API Server**: Central management point
- **etcd**: Cluster state database (backup critical!)
- **Scheduler**: Pod placement decisions
- **Controller Manager**: Reconciliation loops
- **CNI**: Network policy enforcement

### Worker Nodes
- **Kubelet**: Pod lifecycle management
- **Container Runtime**: containerd (run containers)
- **Kube-proxy**: Service networking
- **Pods**: User workloads (AI training, inference, etc.)

## Scalability Considerations

### Adding Nodes
1. Update `terraform.tfvars` with new host entry
2. Ensure join token is valid (refresh if needed)
3. Run `terraform apply`
4. Terraform provisions only new nodes (idempotent)

### High Availability (Future)
```
┌────────────────────────────────────────────────────────────┐
│ Load Balancer (HAProxy/Nginx)                              │
│  • VIP: 192.168.1.100:6443                                 │
└────────┬───────────────┬───────────────┬──────────────────┘
         │               │               │
   ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
   │ Control 1 │   │ Control 2 │   │ Control 3 │
   │ etcd      │◄──┤ etcd      │◄──┤ etcd      │
   └───────────┘   └───────────┘   └───────────┘
         ▲               ▲               ▲
         └───────────────┴───────────────┘
              Worker nodes connect to VIP
```

### Monitoring Stack (Future)
```
Prometheus (metrics) ← Node Exporter (each node)
     ↓
Grafana (visualization)
     ↓
AlertManager (alerts) → Slack/PagerDuty
```

## Disaster Recovery

### Critical Data
1. **etcd snapshots** (control plane):
   ```bash
   ETCDCTL_API=3 etcdctl snapshot save backup.db
   ```
2. **Admin kubeconfig** (WSL): `~/.kube/config`
3. **Terraform state** (HCP): Automatically versioned
4. **Persistent volumes**: External backup solution required

### Recovery Procedure
1. Restore etcd from snapshot
2. Recreate control plane if needed (kubeadm init with --ignore-preflight-errors)
3. Rejoin workers (terraform apply with valid join token)
4. Restore PV data from backups
5. Redeploy applications from Git

## Future Enhancements

### Phase 2: HCP Vault Integration
- Dynamic SSH credential generation
- Automatic kubeadm token rotation
- Application secret injection via Vault Agent

### Phase 3: HCP Consul Integration
- Service mesh for inter-pod communication
- mTLS between services
- Multi-cluster service discovery

### Phase 4: Automation
- Auto-capture join command from control plane
- Automatic CNI installation (Terraform kubernetes provider)
- Self-healing node replacement
- Automated backup scheduling

---

**Last Updated**: November 2025
**Maintainer**: Infrastructure Team
**Support**: See QUICKSTART.md and HCP_SETUP.md
