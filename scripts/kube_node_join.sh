#!/usr/bin/env bash
set -euo pipefail
JOIN_CMD="$1"
if [ -z "$JOIN_CMD" ]; then
  echo "No join command supplied" >&2
  exit 0
fi
if [ -f /etc/kubernetes/kubelet.conf ]; then
  echo "Node appears already joined; skipping join." && exit 0
fi
echo "Executing kubeadm join"
# shellcheck disable=SC2086
eval "$JOIN_CMD"
echo "Join complete"
