# 🌥️ Cloud DevOps Lab 202

This repository contains infrastructure and configuration code for setting up a Cloud DevOps environment using **Terraform**, **Ansible**, and **Docker Compose**.

---

## 📁 Project Overview

- **Terraform**: Infrastructure provisioning (e.g., instances, networks)
- **Ansible**: Configuration management and software installation
- **Docker Compose**: Containerized service deployment (e.g., Jenkins)

---

## ✅ Prerequisites

Make sure the following tools are installed on your system:

- [Terraform](https://www.terraform.io/downloads)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- SSH Key (`auth.pem`) with access to remote servers

---

## 🚀 How to Run This Project

### 1. 🔧 Terraform Setup

Run the following commands in the Terraform directory to provision infrastructure:

```bash
terraform init           # Initialize working directory
terraform fmt            # Format Terraform code
terraform validate       # Validate the configuration
terraform plan           # Review planned actions
terraform apply          # Apply changes to build infrastructure

### giving proper permissions
```bash


chmod 600 ~/.ssh/auth.pem

### running ansible playbook

```bash
ansible-playbook -i hosts.ini playbook.yml --ask-vault-pass




### docker build custom Jenkins containers

```bash

docker compose build jenkins
docker compose up -d




