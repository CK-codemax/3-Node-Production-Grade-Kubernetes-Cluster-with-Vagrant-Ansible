#!/bin/bash

# Setup script for Vagrant Kubernetes cluster
set -e

echo "🚀 Setting up Vagrant Kubernetes cluster..."

# Set up Ansible inventory
echo "📋 Setting up Ansible inventory..."
if [ ! -f "cluster-setup/inventory/hosts.yml" ]; then
    echo "❌ Error: hosts.yml not found!"
    exit 1
fi

echo "✅ Ansible inventory already exists"

echo ""
echo "🎉 Setup complete! You can now:"
echo ""
echo "1. Start the VMs:"
echo "   vagrant up"
echo ""
echo "2. SSH to nodes:"
echo "   vagrant ssh master1  # Master"
echo "   vagrant ssh worker1  # Worker1"
echo "   vagrant ssh worker2  # Worker2"
echo ""
echo "3. Run Ansible playbooks:"
echo "   ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml"
echo ""
echo "📋 Cluster IPs:"
echo "   Master:  192.168.56.10"
echo "   Worker1: 192.168.56.11"
echo "   Worker2: 192.168.56.12"
