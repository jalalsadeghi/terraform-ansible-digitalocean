# Terraform and Ansible for Automated Infrastructure on DigitalOcean

## Table of Contents
- [Introduction](#introduction)
- [Benefits of Terraform and Ansible](#benefits-of-terraform-and-ansible)
- [Why Choose DigitalOcean?](#why-choose-digitalocean)
- [Prerequisites](#prerequisites)
- [Infrastructure Provisioning with Terraform](#infrastructure-provisioning-with-terraform)
  - [Installing Terraform](#installing-terraform)
  - [Creating SSH Keys](#creating-ssh-keys)
  - [Deploying Droplets](#deploying-droplets)
- [Server Configuration with Ansible](#server-configuration-with-ansible)
  - [Installing Ansible](#installing-ansible)
  - [Configuring Ansible Inventory](#configuring-ansible-inventory)
  - [Running the Ansible Playbook](#running-the-ansible-playbook)
- [Verification and Cleanup](#verification-and-cleanup)
- [Conclusion](#conclusion)

## Introduction
This repository demonstrates a modern approach to automating infrastructure provisioning and configuration management using Terraform and Ansible on DigitalOcean. It highlights industry-standard practices suitable for DevOps engineers and infrastructure developers.

## Benefits of Terraform and Ansible
Terraform enables infrastructure provisioning through code, allowing consistent and repeatable deployments across various environments. Ansible complements Terraform by managing configurations and ensuring software consistency on provisioned servers, using human-readable YAML playbooks.

## Why Choose DigitalOcean?
DigitalOcean is popular among developers and startups due to its user-friendly interface, transparent pricing, and scalability. It's ideal for small-to-medium scale web applications, SaaS products, and development environments.

## Prerequisites
- DigitalOcean account and API token
- Terraform installed
- Ansible installed
- SSH key pair

## Infrastructure Provisioning with Terraform
### Installing Terraform
Install Terraform from [HashiCorp's official site](https://developer.hashicorp.com/terraform/downloads) or via package managers such as Homebrew (`brew install terraform`) or APT on Debian-based systems.

### Creating SSH Keys
Generate an SSH key pair with:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```
Upload the public key (`~/.ssh/id_ed25519.pub`) to your DigitalOcean account.

### Deploying Droplets
Use the provided `main.tf` file to provision three Ubuntu 24.04 Droplets:

```hcl
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
```

Run Terraform commands:
```bash
terraform init
terraform apply
```

### Saving and Applying a Terraform Plan (Recommended)
You can save your Terraform execution plan before applying it. This practice helps ensure changes applied to your infrastructure match exactly what you've reviewed and approved.
```bash
terraform plan -out=my-plan
```
Review the saved plan (my-plan) carefully, and once satisfied, apply it using:
```bash
terraform apply my-plan
```

## Server Configuration with Ansible
### Installing Ansible
Install Ansible with:
```bash
sudo apt install -y ansible
```

### Configuring Ansible Inventory
Edit `hosts.ini` with your Droplets' IP addresses:

```ini
[webservers]
64.226.120.206 ansible_user=root ansible_python_interpreter=/usr/bin/python3.12
46.101.170.163 ansible_user=root ansible_python_interpreter=/usr/bin/python3.12
164.92.244.243 ansible_user=root ansible_python_interpreter=/usr/bin/python3.12
```
Recent Ubuntu versions (like Ubuntu 24.04 used here) come with multiple Python versions or might default to different Python paths. Explicitly specifying the Python interpreter ensures Ansible uses the correct Python environment on the remote servers, preventing any unexpected compatibility issues or warnings during playbook execution.
 `ansible_python_interpreter=/usr/bin/python3.12`


### Running the Ansible Playbook
Use the provided `playbook.yml`:

```yaml
---
- name: Install Docker and Docker Compose on Ubuntu 24.04
  hosts: all
  gather_facts: yes
  tasks:
    - name: Update apt cache and upgrade system
      ansible.builtin.apt:
        update_cache: yes
        upgrade: dist
        cache_valid_time: 3600

    - name: Install prerequisite packages
      ansible.builtin.apt:
        name:
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present

    - name: Create directory for APT keys
      ansible.builtin.file:
        path: /etc/apt/keyrings
        state: directory
        mode: '0755'

    - name: Add Docker's official GPG key
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        keyring: /etc/apt/keyrings/docker.gpg
        state: present

    - name: Ensure Docker GPG key permissions
      ansible.builtin.file:
        path: /etc/apt/keyrings/docker.gpg
        mode: '0644'

    - name: Add Docker repository
      ansible.builtin.apt_repository:
        repo: "deb [arch={{ 'amd64' if ansible_architecture == 'x86_64' else 'arm64' }} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        filename: docker.list
        state: present

    - name: Install Docker Engine and Docker Compose
      ansible.builtin.apt:
        update_cache: yes
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: latest

    - name: Verify Docker installation
      ansible.builtin.command: docker --version
      register: docker_version

    - name: Verify Docker Compose installation
      ansible.builtin.command: docker compose version
      register: compose_version

    - name: Display Docker and Docker Compose versions
      ansible.builtin.debug:
        msg: |
          Docker version: {{ docker_version.stdout }}
          Docker Compose version: {{ compose_version.stdout }}
```

### Example Ansible Playbook Output
When running the Ansible playbook, you should expect to see an output similar to the following, indicating that Docker and Docker Compose have been successfully installed and configured on all servers:

```bash
ansible-playbook -i hosts.ini playbook.yml
```
### Sample output:
```bash
PLAY [Install Docker and Docker Compose on Ubuntu 24.04] **********************************************************************

TASK [Gathering Facts] ********************************************************************************************************
ok: [46.101.170.163]
ok: [64.226.120.206]
ok: [164.92.244.243]

TASK [Update apt cache and upgrade system] ************************************************************************************
ok: [46.101.170.163]
ok: [64.226.120.206]
ok: [164.92.244.243]

TASK [Install prerequisite packages] ******************************************************************************************
ok: [46.101.170.163]
ok: [64.226.120.206]
ok: [164.92.244.243]

TASK [Create directory for APT keys (if it doesn't exist)] ********************************************************************
ok: [164.92.244.243]
ok: [64.226.120.206]
ok: [46.101.170.163]

TASK [Add Docker's official GPG key] ******************************************************************************************
ok: [46.101.170.163]
ok: [64.226.120.206]
ok: [164.92.244.243]

TASK [Ensure Docker GPG key file has correct permissions] *********************************************************************
ok: [164.92.244.243]
ok: [64.226.120.206]
ok: [46.101.170.163]

TASK [Add Docker official repository] *****************************************************************************************
ok: [164.92.244.243]
ok: [46.101.170.163]
ok: [64.226.120.206]

TASK [Install Docker Engine and Docker Compose Plugin] ************************************************************************
ok: [164.92.244.243]
ok: [46.101.170.163]
ok: [64.226.120.206]

TASK [Check Docker version] ***************************************************************************************************
changed: [164.92.244.243]
changed: [64.226.120.206]
changed: [46.101.170.163]

TASK [Check Docker Compose version] *******************************************************************************************
changed: [64.226.120.206]
changed: [46.101.170.163]
changed: [164.92.244.243]

TASK [Display installed Docker and Docker Compose versions] *******************************************************************
ok: [64.226.120.206] => {
    "msg": "Docker version: Docker version 28.0.4, build b8034c0\nDocker Compose version: Docker Compose version v2.34.0\n"
}
ok: [46.101.170.163] => {
    "msg": "Docker version: Docker version 28.0.4, build b8034c0\nDocker Compose version: Docker Compose version v2.34.0\n"
}
ok: [164.92.244.243] => {
    "msg": "Docker version: Docker version 28.0.4, build b8034c0\nDocker Compose version: Docker Compose version v2.34.0\n"
}

PLAY RECAP ********************************************************************************************************************
164.92.244.243             : ok=11   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
46.101.170.163             : ok=11   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
64.226.120.206             : ok=11   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

## Verification and Cleanup
Check Docker and Docker Compose installations via SSH, and clean up resources with `terraform destroy` when finished.

## Conclusion
This project demonstrates the efficiency of using Terraform and Ansible for automated and repeatable infrastructure setup, essential skills for modern DevOps roles.
