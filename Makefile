# Makefile for 3-Node Kubernetes Cluster Setup with Vagrant
# This Makefile automates the entire process from VM creation to cluster deployment

.PHONY: help up down provision inventory ping prereq hostnames master cni workers verify all clean setup-vagrant setup-cluster cleanup-cluster clean-cluster clean-infra helm nginx-ingress cert-manager letsencrypt-issuer nfs nfs-provisioner metrics-server dashboard copy-kubedefs tools cleanup-namespaces

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
	@echo "  helm          - Install Helm"
	@echo "  nginx-ingress - Install Nginx Ingress Controller"
	@echo "  cert-manager  - Install cert-manager"
	@echo "  letsencrypt-issuer - Create Let's Encrypt ClusterIssuer"
	@echo "  dashboard     - Install Kubernetes Dashboard (with Let's Encrypt SSL)"
	@echo "  copy-kubedefs - Copy kubedefs to control plane node"
	@echo "  nfs           - Setup NFS server and client"
	@echo "  nfs-provisioner - Install NFS provisioner"
	@echo "  metrics-server - Install Metrics Server"
	@echo "  dashboard     - Install Kubernetes Dashboard (with Let's Encrypt SSL)"
	@echo "  tools         - Install all additional tools (helm, ingress, cert-manager, nfs, metrics, dashboard)"
	@echo "  setup           - Complete setup (VMs + cluster) in one command"
	@echo "  setup-with-tools - Complete setup (VMs + cluster + tools) in one command"
	@echo "  setup-vagrant   - Complete VM setup (up + provision + inventory)"
	@echo "  setup-cluster   - Complete cluster setup"
	@echo "  cleanup-cluster - Clean up Kubernetes resources from VMs"
	@echo "  clean-cluster  - Fast cleanup: kubeadm reset + uninstall tools"
	@echo "  cleanup-namespaces - Clean up stuck namespaces with finalizers"
	@echo "  clean-infra    - Clean up infrastructure: vagrant destroy"
	@echo "  clean         - Clean up generated files"
	@echo ""
	@echo "Quick start:"
	@echo "  make setup         - Complete setup (VMs + cluster) in one go"
	@echo "  make setup-with-tools - Complete setup (VMs + cluster + tools) in one go"
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

helm:
	@echo "Installing Helm..."
	@ansible-playbook cluster-setup/playbooks/09-install-helm.yml

nginx-ingress:
	@echo "Installing Nginx Ingress Controller..."
	@ansible-playbook cluster-setup/playbooks/10-install-nginx-ingress.yml

nfs:
	@echo "Setting up NFS server and client..."
	@ansible-playbook cluster-setup/playbooks/11-setup-nfs.yml

nfs-provisioner:
	@echo "Installing NFS provisioner..."
	@ansible-playbook cluster-setup/playbooks/12-install-nfs-provisioner.yml

metrics-server:
	@echo "Installing Metrics Server..."
	@ansible-playbook cluster-setup/playbooks/13-install-metrics-server.yml

cert-manager:
	@echo "Installing cert-manager..."
	@ansible-playbook cluster-setup/playbooks/14-install-cert-manager.yml

letsencrypt-issuer:
	@echo "Creating Let's Encrypt ClusterIssuer..."
	@ansible-playbook cluster-setup/playbooks/15-create-letsencrypt-issuer.yml

dashboard:
	@echo "Installing Kubernetes Dashboard..."
	@ansible-playbook cluster-setup/playbooks/16-install-kubernetes-dashboard.yml

copy-kubedefs:
	@echo "Copying kubedefs to control plane node..."
	@ansible-playbook cluster-setup/playbooks/17-copy-kubedefs.yml

tools: helm nginx-ingress cert-manager letsencrypt-issuer nfs nfs-provisioner metrics-server dashboard
	@echo ""
	@echo "🎉 All additional tools installed successfully!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Access Kubernetes Dashboard: https://dashboard.ochukowhoro.xyz (with Let's Encrypt SSL)"
	@echo "2. Check metrics: kubectl top nodes"
	@echo "3. Use NFS storage: kubectl get storageclass"
	@echo "4. Check certificate status: kubectl describe certificate dashboard-tls-secret -n kubernetes-dashboard"

autocomplete:
	@echo "Setting up kubectl autocomplete..."
	@ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml

all: kubelet prereq master cni workers verify autocomplete
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

setup-with-tools: setup-vagrant setup-cluster tools
	@echo ""
	@echo "🎉 Complete Kubernetes cluster with tools setup finished!"
	@echo ""
	@echo "Your cluster with all tools is ready! Next steps:"
	@echo "1. SSH to master: vagrant ssh master1"
	@echo "2. Check cluster: kubectl get nodes"
	@echo "3. View pods: kubectl get pods -A"
	@echo "4. Access Dashboard: https://dashboard.ochukowhoro.xyz (Let's Encrypt SSL)"
	@echo "5. Check metrics: kubectl top nodes"
	@echo "6. Check storage: kubectl get storageclass"
	@echo "7. Get dashboard token: kubectl create token dashboard-viewer-sa -n kubernetes-dashboard"
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
	@ansible-playbook cluster-setup/playbooks/20-cleanup-cluster.yml
	@echo ""
	@echo "Kubernetes cleanup completed!"
	@echo "You can now safely run: make destroy"

# Fast Kubernetes cleanup
clean-cluster:
	@echo "Fast Kubernetes cleanup..."
	@ansible-playbook cluster-setup/playbooks/20-cleanup-cluster.yml
	@echo ""
	@echo "Fast Kubernetes cleanup completed!"
	@echo "VMs are still running and ready for new cluster setup."

# Clean up stuck namespaces
cleanup-namespaces:
	@echo "Cleaning up stuck namespaces..."
	@ansible-playbook cluster-setup/playbooks/15-cleanup-namespaces.yml
	@echo ""
	@echo "Namespace cleanup completed!"

# Clean up infrastructure
clean-infra:
	@echo "Cleaning up infrastructure..."
	@vagrant destroy -f
	@echo "Infrastructure cleanup completed!"

# Clean up generated files
clean: cleanup-namespaces clean-cluster clean-infra
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
