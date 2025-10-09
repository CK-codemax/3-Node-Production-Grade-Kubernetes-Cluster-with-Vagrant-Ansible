#!/bin/bash

# Setup script for Vagrant Kubernetes cluster
set -e

echo "🚀 Setting up Vagrant Kubernetes cluster..."

# Generate SSH keys if they don't exist
if [ ! -f "k8s-cluster-key" ]; then
    echo "🔑 Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f k8s-cluster-key -N "" -C "k8s-cluster-$(date +%Y%m%d)"
    chmod 600 k8s-cluster-key
    chmod 644 k8s-cluster-key.pub
    echo "✅ SSH keys generated"
else
    echo "✅ SSH keys already exist"
fi

# Set up Ansible inventory
echo "📋 Setting up Ansible inventory..."
if [ ! -f "cluster-setup/inventory/hosts-template.yml" ]; then
    echo "❌ Error: hosts-template.yml not found!"
    exit 1
fi

cp cluster-setup/inventory/hosts-template.yml cluster-setup/inventory/hosts.yml
echo "✅ Ansible inventory created"

echo ""
echo "🎉 Setup complete! You can now:"
echo ""
echo "1. Start the VMs:"
echo "   vagrant up"
echo ""
echo "2. SSH to nodes:"
echo "   ssh -i k8s-cluster-key vagrant@192.168.56.10  # Master"
echo "   ssh -i k8s-cluster-key vagrant@192.168.56.11  # Worker1"
echo "   ssh -i k8s-cluster-key vagrant@192.168.56.12  # Worker2"
echo ""
echo "3. Run Ansible playbooks:"
echo "   ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml"
echo ""
echo "📋 Cluster IPs:"
echo "   Master:  192.168.56.10"
echo "   Worker1: 192.168.56.11"
echo "   Worker2: 192.168.56.12"
