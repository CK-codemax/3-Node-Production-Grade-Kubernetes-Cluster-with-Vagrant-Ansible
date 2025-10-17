# Makefile for 3-Node Kubernetes Cluster Setup with Vagrant
# This Makefile automates the entire process from VM creation to cluster deployment

.PHONY: help up down provision inventory ping prereq hostnames master cni workers verify all clean setup-vagrant setup-cluster cleanup-cluster clean-cluster clean-infra

# Default target
help:
	@echo "3-Node Kubernetes Cluster Setup"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  help          - Show this help message"
	@echo "  up            - Start Vagrant VMs"
	@echo "  down          - Stop Vagrant VMs"
	@echo "  provision     - Provision VMs with Kubernetes tools"
	@echo "  inventory     - Create inventory file"
	@echo "  ping          - Test connectivity to all nodes"
	@echo "  ssh-config    - Generate SSH config for Ansible"
	@echo "  prereq        - Run prerequisites playbook"
	@echo "  kubelet       - Configure kubelet node IPs"
	@echo "  master        - Initialize master node"
	@echo "  cni           - Install CNI (Calico)"
	@echo "  workers       - Join worker nodes"
	@echo "  verify        - Verify cluster"
	@echo "  all           - Run all Ansible playbooks"
	@echo "  setup           - Complete setup (VMs + cluster) in one command"
	@echo "  setup-vagrant   - Complete VM setup (up + provision + inventory)"
	@echo "  setup-cluster   - Complete cluster setup"
	@echo "  cleanup-cluster - Clean up Kubernetes resources from VMs"
	@echo "  clean-cluster  - Fast cleanup: kubeadm reset + uninstall tools"
	@echo "  clean-infra    - Clean up infrastructure: vagrant destroy"
	@echo "  clean         - Clean up generated files"
	@echo ""
	@echo "Quick start:"
	@echo "  make setup         - Complete setup (VMs + cluster) in one go"
	@echo "  make clean         - Clean up and start over"

# Vagrant commands
up:
	@echo "Starting Vagrant VMs..."
	@vagrant up

down:
	@echo "Stopping Vagrant VMs..."
	@vagrant halt

provision:
	@echo "Provisioning VMs with Kubernetes tools..."
	@vagrant provision

# Create inventory file
inventory:
	@echo "Inventory file already exists with Vagrant IPs"

# Ansible commands
ping:
	@echo "Testing connectivity to all nodes..."
	@ansible all -m ping

prereq:
	@echo "Running prerequisites playbook..."
	@ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml

kubelet:
	@echo "Configuring kubelet node IPs..."
	@ansible-playbook cluster-setup/playbooks/00-configure-kubelet.yml

master:
	@echo "Initializing master node..."
	@ansible-playbook cluster-setup/playbooks/03-initi-master.yml

cni:
	@echo "Installing CNI (Calico)..."
	@ansible-playbook cluster-setup/playbooks/04-install-cni.yml

workers:
	@echo "Joining worker nodes..."
	@ansible-playbook cluster-setup/playbooks/05-join-workers.yml

verify:
	@echo "Verifying cluster..."
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml

autocomplete:
	@echo "Setting up kubectl autocomplete..."
	@ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml

all:
	@echo "Running all Ansible playbooks..."
	@ansible-playbook cluster-setup/playbooks/00-configure-kubelet.yml
	@ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml
	@ansible-playbook cluster-setup/playbooks/03-initi-master.yml
	@ansible-playbook cluster-setup/playbooks/04-install-cni.yml
	@ansible-playbook cluster-setup/playbooks/05-join-workers.yml
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
	@ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml
# Complete setup process
setup: setup-vagrant setup-cluster
	@echo ""
	@echo "🎉 Complete Kubernetes cluster setup finished!"
	@echo ""
	@echo "Your cluster is ready! Next steps:"
	@echo "1. SSH to master: vagrant ssh master1"
	@echo "2. Check cluster: kubectl get nodes"
	@echo "3. View pods: kubectl get pods -A"
	@echo ""
	@echo "To destroy: make clean"

setup-vagrant: up inventory
	@echo ""
	@echo "🎉 Vagrant VM setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Run: make setup-cluster"
	@echo ""

setup-cluster: ssh-config all
	@echo ""
	@echo "🎉 Kubernetes cluster setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. SSH to master: vagrant ssh master1"
	@echo "2. Check cluster: kubectl get nodes"
	@echo "3. View pods: kubectl get pods -A"
	@echo ""
	@echo "To destroy: make clean"

# Generate SSH config for Ansible connectivity
ssh-config:
	@echo "Generating SSH config for Ansible..."
	@vagrant ssh-config > ssh_config

# Clean up Kubernetes resources from VMs
cleanup-cluster:
	@echo "Cleaning up Kubernetes resources from VMs..."
	@ansible-playbook cluster-setup/playbooks/07-cleanup-cluster.yml
	@echo ""
	@echo "Kubernetes cleanup completed!"
	@echo "You can now safely run: make destroy"

# Fast Kubernetes cleanup
clean-cluster:
	@echo "Fast Kubernetes cleanup..."
	@ansible-playbook cluster-setup/playbooks/08-cleanup-cluster.yml
	@echo ""
	@echo "Fast Kubernetes cleanup completed!"
	@echo "VMs are still running and ready for new cluster setup."

# Clean up infrastructure
clean-infra:
	@echo "Cleaning up infrastructure..."
	@vagrant destroy -f
	@echo "Infrastructure cleanup completed!"

# Clean up generated files
clean: clean-cluster clean-infra
	@echo "Cleaning up generated files..."
	@rm -f cluster-setup/inventory/hosts.yml
	@rm -f ansible.log
	@echo "Complete cleanup finished!"

# Development helpers
dev-setup: up
	@echo "Development setup complete. Run 'make provision' to install Kubernetes tools."

dev-ansible: inventory all
	@echo "Ansible setup complete. Cluster should be ready!"

# Status check
status:
	@echo "Checking cluster status..."
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
