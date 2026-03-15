# Terraform language documentation: https://www.terraform.io/docs/language/index.html
# HCL language specification: https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md
# Module documentation: https://registry.terraform.io/modules/identiops/k3s/hcloud/latest
# Copyright 2024, identinet GmbH. All rights reserved.
# SPDX-License-Identifier: MIT

###########################
#  Backend and Providers  #
###########################

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_version = "~> 1.0"
}

###########################
#  Cluster configuration  #
###########################

module "cluster" {
  source                 = "../../"
  hcloud_token           = var.hcloud_token
  hcloud_token_read_only = var.hcloud_token_read_only

  # Cluster Settings
  # ----------------
  delete_protection = true
  cluster_name      = "traefik-demo"
  default_location  = "nbg1"
  default_image     = "ubuntu-24.04"
  k3s_version       = "v1.32.1+k3s1"

  # k3s Config - Enable Traefik and Helm Controller
  # -----------------------------------------------
  # This enables the built-in Traefik ingress controller and Helm controller.
  # The config files are written to /etc/rancher/k3s/config.yaml.d/
  # See: https://docs.k3s.io/installation/configuration#configuration-file
  k3s_config = {
    traefik = {
      enabled = true
    }
    helm-controller = {
      enabled = true
    }
  }

  # SSH Keys
  # --------
  ssh_keys = {
    "admin" = file("~/.ssh/id_ed25519.pub")
  }

  # Gateway Settings
  # ----------------
  gateway_firewall_k8s_open = false
  gateway_server_type       = "cpx11"

  # Control Plane Settings
  # ----------------------
  additional_cloud_init = {
    timezone = "Europe/Berlin"
  }

  # Node Pool Settings
  # ------------------
  node_pools = {
    system = {
      cluster_can_init = true
      cluster_init_action = {
        init = true,
      }
      is_control_plane   = true
      schedule_workloads = false
      type               = "cpx31"
      count              = 3
      labels             = {}
      taints             = {}
    }
    workers = {
      is_control_plane   = false
      schedule_workloads = true
      type               = "cpx31"
      count              = 2
      count_width        = 2
      labels             = {}
      taints             = {}
    }
  }
}

###############
#  Variables  #
###############

variable "hcloud_token" {
  description = "Hetzner cloud auth token."
  type        = string
  sensitive   = true
}

variable "hcloud_token_read_only" {
  description = "Hetzner cloud auth token, read only."
  type        = string
  sensitive   = true
}

############
#  Output  #
############

output "gateway" {
  depends_on  = [module.cluster]
  description = "IP Addresses of the gateway."
  value       = module.cluster.gateway
}

output "node_pools" {
  depends_on  = [module.cluster]
  description = "IP Addresses of the worker node pools."
  value       = module.cluster.node_pools
}

output "k3s_config" {
  depends_on  = [module.cluster]
  description = "Configured k3s components."
  value       = module.cluster.k3s_config
}
