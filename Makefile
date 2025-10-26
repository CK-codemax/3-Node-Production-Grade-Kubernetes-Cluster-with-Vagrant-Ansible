# Makefile for 3-Node Kubernetes Cluster Setup
# Automates VM creation, cluster deployment, and tool installation

.PHONY: help setup setup-with-tools setup-vagrant setup-cluster \
        up down provision ssh-config ping \
        kubelet prereq master cni workers verify autocomplete etcd-client all \
        helm nginx-ingress nfs nfs-provisioner metrics-server dashboard \
        argocd argocd-cli argocd-vprofile etcd-backup tools \
        clean-cluster clean-infra clean status

# Default target
help:
	@echo "3-Node Kubernetes Cluster Setup"
	@echo "================================"
	@echo ""
	@echo "Quick Start:"
	@echo "  make setup              - Complete setup (VMs + cluster)"
	@echo "  make setup-with-tools   - Full setup with all tools"
	@echo "  make clean              - Destroy everything"
	@echo ""
	@echo "Core Commands:"
	@echo "  up                - Start Vagrant VMs"
	@echo "  down              - Stop Vagrant VMs"
	@echo "  provision         - Provision VMs with K8s tools"
	@echo "  setup-vagrant     - Complete VM setup"
	@echo "  setup-cluster     - Deploy Kubernetes cluster"
	@echo ""
	@echo "Cluster Management:"
	@echo "  kubelet           - Configure kubelet"
	@echo "  master            - Initialize master"
	@echo "  cni               - Install Calico CNI"
	@echo "  workers           - Join workers"
	@echo "  verify            - Verify cluster"
	@echo "  etcd-client       - Install etcd-client"
	@echo "  etcd-backup       - Setup ETCD backup cron"
	@echo ""
	@echo "Tools (install individually or use 'make tools'):"
	@echo "  helm              - Install Helm"
	@echo "  nginx-ingress     - Install NGINX Ingress"
	@echo "  nfs               - Setup NFS"
	@echo "  nfs-provisioner   - NFS provisioner"
	@echo "  metrics-server    - Metrics Server"
	@echo "  dashboard         - Kubernetes Dashboard"
	@echo "  argocd            - Install ArgoCD"
	@echo "  argocd-cli        - ArgoCD CLI"
	@echo "  argocd-vprofile   - Deploy VProfile (GitOps)"
	@echo "  tools             - Install all tools"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean-cluster     - Reset cluster (keep VMs)"
	@echo "  clean-infra       - Destroy VMs"
	@echo "  clean             - Complete cleanup"
	@echo ""
	@echo "Utilities:"
	@echo "  ping              - Test Ansible connectivity"
	@echo "  ssh-config        - Regenerate SSH config"
	@echo "  status            - Check cluster status"

# ==============================================================================
# Main Workflows
# ==============================================================================

setup: setup-vagrant setup-cluster
	@echo ""
	@echo "🎉 Kubernetes cluster ready!"
	@echo ""
	@echo "Access cluster:"
	@echo "  vagrant ssh master1"
	@echo "  kubectl get nodes"
	@echo ""
	@echo "Install tools: make tools"
	@echo "Cleanup: make clean"

setup-with-tools: setup-vagrant setup-cluster tools
	@echo ""
	@echo "🎉 Complete setup finished!"
	@echo ""
	@echo "Services:"
	@echo "  Dashboard: https://dashboard.ochukowhoro.xyz"
	@echo "  ArgoCD: https://argo.ochukowhoro.xyz"
	@echo "  VProfile: https://vprofile.ochukowhoro.xyz"
	@echo ""
	@echo "Get dashboard token:"
	@echo "  kubectl create token dashboard-viewer-sa -n kubernetes-dashboard"
	@echo ""
	@echo "Get ArgoCD password:"
	@echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

setup-vagrant: up
	@echo ""
	@echo "✅ VMs created!"
	@echo "Next: make setup-cluster"

setup-cluster: ssh-config all
	@echo ""
	@echo "✅ Cluster deployed!"
	@echo ""
	@echo "Verify:"
	@echo "  vagrant ssh master1"
	@echo "  kubectl get nodes"
	@echo "  kubectl get pods -A"

# ==============================================================================
# Vagrant Commands
# ==============================================================================

up:
	@echo "Starting Vagrant VMs..."
	@vagrant up

down:
	@echo "Stopping Vagrant VMs..."
	@vagrant halt

provision:
	@echo "Provisioning VMs..."
	@vagrant provision

ssh-config:
	@echo "Generating SSH config..."
	@vagrant ssh-config > ssh_config

# ==============================================================================
# Cluster Deployment
# ==============================================================================

ping:
	@echo "Testing connectivity..."
	@ansible all -m ping

prereq:
	@ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml

kubelet:
	@ansible-playbook cluster-setup/playbooks/00-configure-kubelet.yml

master:
	@ansible-playbook cluster-setup/playbooks/03-initi-master.yml

cni:
	@ansible-playbook cluster-setup/playbooks/04-install-cni.yml

workers:
	@ansible-playbook cluster-setup/playbooks/05-join-workers.yml

verify:
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml

autocomplete:
	@ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml

etcd-client:
	@ansible-playbook cluster-setup/playbooks/08-install-etcd-client.yml

etcd-backup:
	@ansible-playbook cluster-setup/playbooks/19-setup-cron.yml

# ==============================================================================
# Tools Installation
# ==============================================================================

helm:
	@ansible-playbook cluster-setup/playbooks/09-install-helm.yml

nginx-ingress:
	@ansible-playbook cluster-setup/playbooks/10-install-nginx-ingress.yml

nfs:
	@ansible-playbook cluster-setup/playbooks/11-setup-nfs.yml

nfs-provisioner:
	@ansible-playbook cluster-setup/playbooks/12-install-nfs-provisioner.yml

metrics-server:
	@ansible-playbook cluster-setup/playbooks/13-install-metrics-server.yml

dashboard:
	@ansible-playbook cluster-setup/playbooks/14-install-kubernetes-dashboard.yml

argocd:
	@ansible-playbook cluster-setup/playbooks/15-install-argocd.yml

argocd-cli:
	@ansible-playbook cluster-setup/playbooks/16-install-argocd-cli.yml

argocd-vprofile:
	@ansible-playbook cluster-setup/playbooks/18-setup-argocd-vprofile-app.yml
	@echo ""
	@echo "📦 VProfile deployed via GitOps!"
	@echo "Monitor: kubectl get applications -n argocd"

tools: helm nginx-ingress nfs nfs-provisioner metrics-server dashboard argocd argocd-cli argocd-vprofile
	@echo ""
	@echo "🎉 All tools installed!"
	@echo ""
	@echo "Access services at:"
	@echo "  - Dashboard: https://dashboard.ochukowhoro.xyz"
	@echo "  - ArgoCD: https://argo.ochukowhoro.xyz"
	@echo "  - VProfile: https://vprofile.ochukowhoro.xyz"


all: kubelet prereq master cni workers verify autocomplete tools
	@echo "✅ Cluster deployed successfully!"

# ==============================================================================
# Cleanup
# ==============================================================================

clean-cluster:
	@echo "Resetting cluster..."
	@ansible-playbook cluster-setup/playbooks/20-cleanup-cluster.yml
	@echo "✅ Cluster reset! VMs still running."
	@echo "Redeploy: make setup-cluster"

clean-infra:
	@echo "Destroying VMs..."
	@vagrant destroy -f
	@echo "✅ VMs destroyed!"

clean: clean-cluster clean-infra
	@echo "Cleaning up files..."
	@rm -f ssh_config ansible.log
	@echo "✅ Complete cleanup finished!"

# ==============================================================================
# Utilities
# ==============================================================================

status:
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
