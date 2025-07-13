# ----------------------------
# versions.tf
#
# This file sets up the scalable Kubernetes AI infrastructure using Terraform.
# 

# ----------------------------
# Root Module: versions.tf
# ----------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }

    ssh = {
      source  = "loafoe/ssh"
      version = "~> 2.7.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.0"
    }

    # Optional (only if you use kubectl manifests)
    # kubectl = {
    #   source  = "gavinbunney/kubectl"
    #   version = "~> 1.14.0"
    # }
  }

}


