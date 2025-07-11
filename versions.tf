terraform {
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
  }
}