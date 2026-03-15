# Traefik with Hetzner Cloud Load Balancer

This example demonstrates how to use the file-based k3s configuration approach to enable Traefik ingress controller with a Hetzner Cloud Load Balancer.

## Features

- Enables built-in Traefik ingress controller via `k3s_config`
- Enables Helm controller for HelmChartConfig support
- Configures Traefik to use Hetzner Cloud Load Balancer
- Enables Proxy Protocol for correct client IP forwarding
- HTTP to HTTPS redirect

## Prerequisites

- Hetzner Cloud API token (read/write)
- Hetzner Cloud API token (read-only)
- SSH public key at `~/.ssh/id_ed25519.pub`

## Usage

### 1. Set environment variables

```bash
export TF_VAR_hcloud_token="your-hcloud-token"
export TF_VAR_hcloud_token_read_only="your-read-only-token"
```

### 2. Deploy the cluster

```bash
terraform init
terraform apply
```

### 3. Configure kubectl

After the cluster is deployed, configure your kubectl context:

```bash
# Get kubeconfig from one of the control plane nodes
# Use the SSH config created by the module
ssh -F .ssh/config hetzner-system-0 "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig

# Update the server address in kubeconfig to use the gateway
sed -i 's/127.0.0.1/<gateway-ip>/' kubeconfig

# Set KUBECONFIG
export KUBECONFIG=kubeconfig
```

### 4. Apply Traefik configuration

Apply the HelmChartConfig to configure Traefik with Hetzner Load Balancer:

```bash
kubectl apply -f traefik-config.yaml
```

### 5. Verify Load Balancer

Check that the Load Balancer service was created:

```bash
kubectl get svc -n kube-system traefik
```

You should see an external IP assigned by the Hetzner Load Balancer.

## k3s Config Structure

The module creates these configuration files:

| File | Purpose |
|------|---------|
| `/etc/rancher/k3s/config.yaml.d/00-default.yaml` | Module defaults (cluster-cidr, service-cidr, etc.) |
| `/etc/rancher/k3s/config.yaml.d/10-user.yaml` | User-configurable component enables/disables |

## Load Balancer Annotations

Key annotations used in the Traefik configuration:

| Annotation | Description |
|------------|-------------|
| `load-balancer.hetzner.cloud/use-private-ip` | Use private network for node communication |
| `load-balancer.hetzner.cloud/location` | Load balancer location |
| `load-balancer.hetzner.cloud/type` | Load balancer type (lb11, lb21, etc.) |

See the [Hetzner CCM documentation](https://github.com/hetznercloud/hcloud-cloud-controller-manager/blob/main/docs/reference/load_balancer_annotations.md) for all available annotations.

## Cleanup

```bash
# Set delete_protection = false in main.tf and apply first
terraform apply

# Then destroy
terraform destroy
```
