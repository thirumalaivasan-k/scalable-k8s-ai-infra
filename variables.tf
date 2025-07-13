# ----------------------------
# variables.tf
#
# This file sets up the scalable Kubernetes AI infrastructure using Terraform.
# 

# ----------------------------
# Root Module: variables.tf
# ----------------------------
# variables.tf
variable "ssh_user"        { type = string }
variable "ssh_private_key" {
  description = "Private SSH key for connecting to nodes"
  type        = string
  sensitive   = true
}


variable "pod_cidr"        { type = string }
variable "network_plugin"  { type = string }

variable "primary_master" {
  type = object({
    hostname   = string
    ip_address = string
  })
}

variable "master_nodes" {
  type = map(object({
    hostname   = string
    ip_address = string
  }))
}

variable "worker_nodes" {
  type = map(object({
    hostname   = string
    ip_address = string
  }))
}
