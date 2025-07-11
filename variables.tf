variable "hosts" {
  description = "Map of on-prem hosts keyed by name with attributes: ip, user (optional, falls back to ssh_user), role (control|worker)."
  type = map(object({
    ip   = string
    user = optional(string)
    role = string
  }))
}
variable "cluster_ip" {
  description = "IP address of the Kubernetes control plane (used in kubeadm join)"
  type        = string
  default     = ""
}
variable "ssh_private_key" {
  description = "Private SSH key content used for all hosts (store as sensitive in HCP Terraform)."
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "Default SSH user for all servers (used when a host entry omits user)."
  type        = string
}

variable "kube_join_command" {
  description = "Full kubeadm join command for workers (including --token and --discovery-token-ca-cert-hash). Store as SENSITIVE in HCP Terraform."
  type        = string
  sensitive   = true
  default     = ""
}

variable "control_plane_join_command" {
  description = "kubeadm join command for additional control-plane nodes (includes --control-plane and --certificate-key). Sensitive in HCP Terraform. Leave empty if no HA or only single control-plane."
  type        = string
  sensitive   = true
  default     = ""
}

variable "script_url" {
  description = "URL to k8s-prepare.sh script (can be GitHub raw URL or internal repo). If empty, uses local scripts/ folder."
  type        = string
  default     = ""
}

variable "install_containerd_version" {
  description = "Containerd package version (optional pin)."
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version (apt pin like 1.29.3-00) or empty for latest from repo. Store in terraform.tfvars or HCP var."
  type        = string
  default     = ""
}

variable "http_proxy" {
  description = "Optional HTTP proxy for apt/network if needed. Non-sensitive, can be in tfvars."
  type        = string
  default     = ""
}

variable "https_proxy" {
  description = "Optional HTTPS proxy for apt/network if needed. Non-sensitive, can be in tfvars."
  type        = string
  default     = ""
}

variable "no_proxy" {
  description = "NO_PROXY list for containerd and kubelet if using proxies. Non-sensitive, can be in tfvars."
  type        = string
  default     = ""
}
