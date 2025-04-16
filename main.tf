# Terraform configuration for creating DigitalOcean Droplets (servers)
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37.0"
    }
  }
}

# Configure DigitalOcean Provider with your personal token
provider "digitalocean" {
  token = "YOUR_DIGITALOCEAN_API_TOKEN"  # Replace this with your actual DigitalOcean API token
}

# Variable to control number of droplets (servers)
variable "droplet_count" {
  default = 3  # This creates 3 droplets by default
}

# Create an SSH key resource in DigitalOcean
resource "digitalocean_ssh_key" "terraform_ssh_key" {
  name       = "terraform-key"                          # Name for your SSH key in DigitalOcean
  public_key = file("/root/.ssh/id_ed25519.pub")        # Path to your SSH public key
}

# Create multiple DigitalOcean Droplets with Ubuntu 24.04
resource "digitalocean_droplet" "myservers" {
  count    = var.droplet_count                          # Number of droplets to create
  image    = "ubuntu-24-04-x64"                         # OS image to install
  name     = "terraform-server-${count.index + 1}"      # Naming droplets sequentially
  region   = "fra1"                                     # Region for droplets (Frankfurt)
  size     = "s-1vcpu-512mb-10gb"                       # Droplet size (smallest, cheapest)

  ssh_keys = [digitalocean_ssh_key.terraform_ssh_key.fingerprint] # SSH key for access
}

# Output public IP addresses of created droplets
output "droplet_public_ips" {
  description = "Public IP addresses of created droplets"
  value       = digitalocean_droplet.myservers[*].ipv4_address
}