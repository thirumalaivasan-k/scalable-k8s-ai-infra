#!/usr/bin/env bash
set -euo pipefail
ROLE="${ROLE:-worker}"
KUBE_VERSION="${KUBE_VERSION:-}"
CONTAINERD_VERSION="${CONTAINERD_VERSION:-}"
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"
NO_PROXY="${NO_PROXY:-}"

if [ -f /etc/kubernetes/prepared ]; then
  echo "Prerequisites already installed. Skipping." && exit 0
fi

echo "[1/9] Disabling swap"
swapoff -a || true
sed -i '/swap/d' /etc/fstab || true

echo "[2/9] Loading kernel modules"
modprobe overlay || true
modprobe br_netfilter || true
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "[3/9] Sysctl params"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null

echo "[4/9] Installing dependencies"
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release

if [ -n "$HTTP_PROXY$HTTPS_PROXY" ]; then
  echo "Configuring proxy environment"
  cat <<EOF >/etc/profile.d/proxy.sh
export HTTP_PROXY=$HTTP_PROXY
export HTTPS_PROXY=$HTTPS_PROXY
export NO_PROXY=$NO_PROXY
EOF
fi

echo "[5/9] Installing containerd"
apt-get install -y containerd || true
if [ -n "$CONTAINERD_VERSION" ]; then
  apt-get install -y containerd="$CONTAINERD_VERSION" || true
fi
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
# Use systemd cgroup driver
sed -i 's/"SystemdCgroup": false/"SystemdCgroup": true/' /etc/containerd/config.toml
grep -q SystemdCgroup /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "[6/9] Add Kubernetes apt repo"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
# Using v1.29 stable repo path (adjust if pinning other version)
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -y

PKG_VERSION=""
if [ -n "$KUBE_VERSION" ]; then
  PKG_VERSION="=${KUBE_VERSION}"
fi

echo "[7/9] Installing kubeadm, kubelet, kubectl $PKG_VERSION"
apt-get install -y kubelet$PKG_VERSION kubeadm$PKG_VERSION kubectl$PKG_VERSION
apt-mark hold kubelet kubeadm kubectl

echo "[8/9] Enabling kubelet (will wait for kubeadm)"
systemctl enable kubelet

if [ "$ROLE" = "control" ]; then
  echo "Control plane node prepared. Run kubeadm init manually or automate separately."
else
  echo "Worker node prepared. Awaiting join command."
fi

echo "[9/9] Mark prepared"
touch /etc/kubernetes/prepared

echo "Prerequisites installation complete"
