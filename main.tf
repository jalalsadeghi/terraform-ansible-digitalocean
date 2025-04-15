# Terraform Configuration for DigitalOcean	
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# DigitalOcean provider configuration
provider "digitalocean" {
  token = "YOUR_DIGITALOCEAN_API_TOKEN"  # Replace with your DigitalOcean token
}

variable "droplet_count" {
  default = 3
}

# Create SSH key resource on DigitalOcean
resource "digitalocean_ssh_key" "terraform_ssh_key" {
  name       = "terraform-key"                             # Name of SSH key in DigitalOcean
  public_key = file("/root/.ssh/id_ed25519.pub")           # Path to your public SSH key
}

# Create 3 DigitalOcean droplets with Ubuntu 24.04
resource "digitalocean_droplet" "myservers" {
  count  = var.droplet_count                               # Number of droplets to create
  image  = "ubuntu-24-04-x64"                              # OS image
  name   = "terraform-server-${count.index + 1}"           # Naming droplets sequentially
  region = "fra1"                                          # Droplet region (Frankfurt)
  size   = "s-1vcpu-512mb-10gb"                            # Droplet size/type

  # Assign the SSH key for droplet access
  ssh_keys = [digitalocean_ssh_key.terraform_ssh_key.fingerprint]
}

resource "digitalocean_project_resources" "first_project_assignment" {
  project = "first-project"
  resources = digitalocean_droplet.myservers[*].urn
  depends_on = [digitalocean_droplet.myservers]
}