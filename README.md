# 3-Node Production Grade Kubernetes Cluster with Vagrant & Ansible

![Kubernetes](https://img.shields.io/badge/kubernetes-v1.28-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-automated-EE0000?style=flat&logo=ansible&logoColor=white)
![Vagrant](https://img.shields.io/badge/vagrant-vms-1868F2?style=flat&logo=vagrant&logoColor=white)
![ArgoCD](https://img.shields.io/badge/argocd-gitops-EF7B4D?style=flat&logo=argo&logoColor=white)

> **Production-ready Kubernetes infrastructure** demonstrating enterprise-grade cluster management, GitOps practices, and automated deployment workflows.

This project showcases expertise in **bare-metal Kubernetes management** and **infrastructure automation**. It features a complete 3-node cluster built from scratch using kubeadm, automated with Ansible, and enhanced with production-grade tools including Helm, NGINX Ingress, NFS storage provisioning, Metrics Server, Kubernetes Dashboard, and ArgoCD for GitOps continuous delivery. The setup culminates with an automated deployment of a multi-tier Java application (VProfile) demonstrating real-world microservices architecture.

## 🚀 Quick Start

```bash
# Complete setup (15-20 minutes)
make setup-with-tools

# Or step by step
make setup              # VMs + Kubernetes cluster (10 min)
make tools              # Dashboard, ArgoCD, monitoring (10 min)

# Access cluster
vagrant ssh master1
kubectl get nodes
```

## 📋 What You Get

### Infrastructure
- **3 VMs**: 1 master (4GB RAM), 2 workers (4GB RAM each)
- **Ubuntu 22.04 LTS** on VirtualBox
- **Private network**: 192.168.56.10-12
- **Kubernetes v1.28** with kubeadm

### Cluster Components
- ✅ **Calico CNI** for pod networking
- ✅ **Helm 3** - Package manager
- ✅ **NGINX Ingress** - External access
- ✅ **NFS Provisioner** - Dynamic storage
- ✅ **Metrics Server** - `kubectl top` support
- ✅ **Kubernetes Dashboard** - Web UI
- ✅ **ArgoCD** - GitOps continuous delivery
- ✅ **VProfile App** - Sample microservices (via ArgoCD)

## 🏗️ Architecture

```
┌────────────────────────────────────────────┐
│         Vagrant VMs (VirtualBox)           │
│                                            │
│  ┌──────────────┐  ┌──────────────┐       │
│  │  Master-1    │  │  Worker-1    │       │
│  │ (Control     │  │  (Compute)   │       │
│  │  Plane)      │  │              │       │
│  │ 192.168.56.10│  │192.168.56.11 │       │
│  │  4GB / 2CPU  │  │  6GB / 2CPU  │       │
│  └──────────────┘  └──────────────┘       │
│                                            │
│  ┌──────────────┐                         │
│  │  Worker-2    │                         │
│  │  (Compute)   │                         │
│  │192.168.56.12 │                         │
│  │  6GB / 2CPU  │                         │
│  └──────────────┘                         │
└────────────────────────────────────────────┘
```

## Prerequisites

**Tools:** VirtualBox, Vagrant, Ansible 

**System Requirements:** 16GB RAM, 20GB disk, 4+ CPU cores

**DNS Configuration (for ingress):**
- Create A records with your domain provider:
  - `dashboard.yourdomain.com` → `192.168.56.10`
  - `argo.yourdomain.com` → `192.168.56.10`
  - `vprofile.yourdomain.com` → `192.168.56.10`

**Note:** Since this uses private VM IPs, SSL certificates cannot be automatically provisioned. Browser security warnings are expected and normal for local development.

## 📚 Usage

### Essential Commands

```bash
# Setup
make setup              # Create VMs + deploy Kubernetes

# Access
vagrant ssh master1     # SSH to master
vagrant ssh worker1     # SSH to worker1
vagrant ssh worker2     # SSH to worker2

# Cleanup
make clean-cluster      # Reset cluster (keep VMs)
make clean              # Destroy everything
```

### Available Commands

<details>
<summary>View all commands</summary>

**Setup:**
- `make setup` - Complete automated setup ⭐
- `make setup-vagrant` - Create VMs only
- `make setup-cluster` - Deploy Kubernetes only
- `make setup-with-tools` - Full setup + tools

**Cluster:**
- `make master` - Initialize master
- `make cni` - Install Calico CNI
- `make workers` - Join workers
- `make verify` - Verify cluster
- `make etcd-client` - Install etcd-client
- `make etcd-backup` - Setup ETCD backup cron (every 2 min)

**Tools:**
- `make helm` - Install Helm
- `make nginx-ingress` - NGINX Ingress
- `make nfs` - Setup NFS
- `make nfs-provisioner` - NFS provisioner
- `make metrics-server` - Metrics Server
- `make dashboard` - Kubernetes Dashboard
- `make argocd` - Install ArgoCD
- `make argocd-cli` - ArgoCD CLI
- `make argocd-vprofile` - Deploy VProfile app
- `make tools` - Install all tools

**Cleanup:**
- `make clean-cluster` - Reset cluster
- `make clean-infra` - Destroy VMs
- `make clean` - Complete cleanup

**Utilities:**
- `make ping` - Test connectivity
- `make ssh-config` - Regenerate SSH config
- `make status` - Check cluster status
</details>

## 🔐 Accessing Services

### Kubernetes Dashboard
```bash
# URL: https://dashboard.ochukowhoro.xyz
kubectl create token dashboard-viewer-sa -n kubernetes-dashboard
# Browser warning expected
```

### ArgoCD
```bash
# URL: https://argo.ochukowhoro.xyz
# Username: admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### VProfile Application
```bash
# URL: https://vprofile.ochukowhoro.xyz
# Username: admin_vp
# Password: admin_vp

# Monitor deployment
kubectl get applications -n argocd
kubectl get pods -n vprofile
```

## 🛠️ Common Tasks

### Verify Cluster
```bash
vagrant ssh master1
kubectl get nodes
kubectl get pods -A
kubectl top nodes
```

### ETCD Backup & Restore
```bash
# Setup automated backups (runs every 2 minutes)
make etcd-backup

# Check backups
vagrant ssh master1
sudo ls -lh /var/backups/etcd/

# View backup logs
sudo tail -f /var/log/etcd-backup.log

# Manual backup
sudo /usr/local/bin/etcd-backup.sh

# Restore from backup
ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/etcd-YYYY-MM-DD_HH-MM-SS.db \
  --data-dir=/var/lib/etcd-restore

# Check etcd health
sudo etcd-health
sudo etcd-status
```

### Restart Cluster (Keep VMs)
```bash
make clean-cluster
make setup-cluster
make tools
```

### Update VM Memory
1. Edit `Vagrantfile` (change memory/CPU)
2. Run: `vagrant reload`
3. Reset cluster: `make clean-cluster && make setup-cluster`

## 🐛 Troubleshooting

### SSH/Ansible Issues
```bash
make ssh-config        # Most common fix
ansible all -m ping    # Test connectivity
```

### API Server Not Responding
```bash
# After VM restart/reload
make clean-cluster
make setup-cluster
```

### Pods Not Scheduling
```bash
kubectl describe nodes | grep -A 5 "Allocated resources"
# Increase memory in Vagrantfile, then vagrant reload
```

### Worker Not Joining
```bash
vagrant ssh master1
kubeadm token create --print-join-command
# Use command on worker node
```

## 🎓 Use Cases

Perfect for learning and practicing:
- Kubernetes cluster setup from scratch
- GitOps with ArgoCD
- Ingress and load balancing
- Persistent storage with NFS
- Monitoring and metrics
- High availability patterns
- Cluster maintenance

## 📝 Configuration

- **Hostnames**: master-1, worker-1, worker-2
- **Network**: Private network (192.168.56.0/24)
- **Pod CIDR**: 192.168.0.0/16 (Calico)
- **Service CIDR**: 10.96.0.0/12
- **Ingress**: NGINX (NodePort mode)

## 🔗 Related Projects

- [argo-project-defs](https://github.com/CK-codemax/argo-project-defs) - GitOps application definitions

---

**Built by**: [Whoro Ochuko](https://github.com/CK-codemax) 
**Built with**: Vagrant • Ansible • Kubernetes • Helm • ArgoCD  
**Perfect for**: Learning, Development, Training, Portfolio
