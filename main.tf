terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}

# This configuration assumes the servers already exist and are reachable via SSH.
# Terraform will not create them; it only configures them using remote-exec.

locals {
  workers = { for k, v in var.hosts : k => v if v.role == "worker" }
  controls = { for k, v in var.hosts : k => v if v.role == "control" }
}

resource "null_resource" "prepare_nodes" {
  for_each = var.hosts

  triggers = {
    host_ip          = each.value.ip
    role             = each.value.role
    prereq_version   = var.kubernetes_version
    containerd_pin   = var.install_containerd_version
    join_cmd_hash    = sha1(var.kube_join_command)
    script_url       = var.script_url
  }

  connection {
    type        = "ssh"
    host        = each.value.ip
    # Fallback: if per-host user is empty or not provided, use global ssh_user variable
    user        = coalesce(each.value.user, var.ssh_user)
    # Updated to use singular ssh_private_key variable defined in variables.tf
    private_key = var.ssh_private_key
    timeout     = "90s"
  }

  # Conditional: download from URL or upload local scripts
  provisioner "remote-exec" {
    inline = var.script_url != "" ? [
      "curl -fsSL ${var.script_url} -o /tmp/k8s-prepare.sh",
      "chmod +x /tmp/k8s-prepare.sh"
    ] : []
  }

  provisioner "file" {
    source      = var.script_url == "" ? "scripts/install_prereqs.sh" : "/dev/null"
    destination = "/tmp/install_prereqs.sh"
  }

  provisioner "file" {
    source      = var.script_url == "" ? "scripts/kube_node_join.sh" : "/dev/null"
    destination = "/tmp/kube_node_join.sh"
  }

  provisioner "remote-exec" {
    inline = concat(
      var.script_url == "" ? ["chmod +x /tmp/install_prereqs.sh /tmp/kube_node_join.sh"] : [],
      [
        # Run prep script with environment variables
        templatefile("${path.module}/scripts/run_prereqs.tftpl", {
          role               = each.value.role
          kube_version       = var.kubernetes_version
          containerd_version = var.install_containerd_version
          http_proxy         = var.http_proxy
          https_proxy        = var.https_proxy
          no_proxy           = var.no_proxy
          script_path        = var.script_url != "" ? "/tmp/k8s-prepare.sh" : "/tmp/install_prereqs.sh"
        }),
        # Conditional join logic for workers and additional control planes
        each.value.role == "worker" && var.kube_join_command != "" ? "sudo ${var.kube_join_command}" : (
          each.value.role == "control" && var.control_plane_join_command != "" ? "sudo ${var.control_plane_join_command}" : "echo 'No applicable join command for this node role. Skipping.'"
        )
      ]
    )
  }
}

output "configured_hosts" {
  value = { for k, v in var.hosts : k => v.ip }
}
