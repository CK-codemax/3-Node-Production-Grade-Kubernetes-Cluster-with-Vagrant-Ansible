# 3-Node Production Grade Kubernetes Cluster with Vagrant & Ansible

![Kubernetes](https://img.shields.io/badge/kubernetes-v1.28-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-automated-EE0000?style=flat&logo=ansible&logoColor=white)
![Vagrant](https://img.shields.io/badge/vagrant-vms-1868F2?style=flat&logo=vagrant&logoColor=white)
![ArgoCD](https://img.shields.io/badge/argocd-gitops-EF7B4D?style=flat&logo=argo&logoColor=white)

> **Production-ready Kubernetes infrastructure** demonstrating enterprise-grade cluster management, GitOps practices, and automated deployment workflows.

## 📖 What This Project Does

This project **automates the complete lifecycle** of setting up a production-grade Kubernetes cluster from scratch on your local machine. It demonstrates end-to-end infrastructure-as-code practices by:

### **🏗️ Infrastructure Provisioning**
- **Creates 3 Ubuntu VMs** using Vagrant and VirtualBox (1 master node + 2 worker nodes)
- **Provisions each VM** with containerd runtime, kubeadm, kubelet, and kubectl
- **Configures networking** with static IPs (192.168.56.10-12) on a private network
- **Handles DNS resolution** by disabling systemd-resolved and using public DNS servers (Google/Cloudflare)
- **Sets up proper hostnames** and `/etc/hosts` entries for inter-node communication

### **☸️ Kubernetes Cluster Deployment**
Using **20+ idempotent Ansible playbooks**, the project orchestrates:
- **Initializes master node** with `kubeadm init` using the Calico pod network CIDR (192.168.0.0/16)
- **Deploys Calico CNI** (Container Network Interface) for pod-to-pod networking across nodes
- **Joins worker nodes** to the cluster using dynamically generated join tokens
- **Configures kubelet** on all nodes with proper node IPs for the private network
- **Sets up kubectl autocomplete** and kubeconfig for easy cluster management

### **🔧 Production Tools Installation**
Automatically installs and configures enterprise-grade tools:
- **Helm 3** - Kubernetes package manager for deploying complex applications
- **NGINX Ingress Controller** - Layer 7 load balancer for HTTP/HTTPS routing to services
- **NFS Server** (on master) + **NFS Client Provisioner** - Dynamic persistent volume provisioning
- **Metrics Server** - Enables `kubectl top nodes/pods` for resource monitoring
- **Kubernetes Dashboard** - Official web UI with HTTPS ingress and RBAC service account
- **ArgoCD** - GitOps continuous delivery tool with CLI and HTTPS ingress
- **ETCD Backup Automation** - Cron job running every 2 minutes with 7-day retention policy

### **🚀 Application Deployment via GitOps**
- **Deploys VProfile** (a multi-tier Java web application) using ArgoCD
- Demonstrates **GitOps workflow** where application state is declared in Git
- ArgoCD automatically syncs and deploys: Nginx, Tomcat, MySQL, Memcached, and RabbitMQ
- Showcases **microservices architecture** with multiple interconnected services

### **🎯 What You'll Learn**
This project is a **comprehensive learning platform** that teaches:
- **Kubernetes from scratch** - Understanding every component and how they work together
- **Infrastructure as Code** - Using Vagrant for VMs and Ansible for configuration management
- **Container orchestration** - How Kubernetes schedules, scales, and manages containerized applications
- **Networking** - CNI plugins, service discovery, ingress controllers, and DNS
- **Storage** - Persistent volumes, storage classes, and dynamic provisioning
- **Security** - RBAC, service accounts, TLS certificates for ingress
- **Monitoring** - Metrics collection and resource monitoring
- **GitOps** - Declarative application deployment with ArgoCD
- **Backup & Recovery** - ETCD backup strategies for disaster recovery
- **Production best practices** - High availability, resource limits, health checks

### **💼 Real-World Skills Demonstrated**
This project mirrors production environments found in enterprises:
- **Multi-node cluster management** - Same approach used for bare-metal production clusters
- **Automation at scale** - Ansible playbooks are reusable and can scale to 100+ nodes
- **Zero-downtime deployments** - ArgoCD enables rolling updates and automated rollbacks
- **Disaster recovery** - Automated ETCD backups ensure cluster state can be restored
- **Observability** - Metrics Server provides foundation for monitoring (can extend to Prometheus/Grafana)
- **Developer experience** - Dashboard and ingress make it easy for teams to deploy and monitor apps

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

## 🔄 How It Works: Complete Workflow

This section explains the **end-to-end automation workflow** and what happens behind the scenes:

### **Phase 1: VM Creation & Provisioning** (`make setup-vagrant`)

**Step 1: Vagrant spins up 3 VMs**
```bash
# Vagrantfile orchestrates VirtualBox to create:
- master-1: 192.168.56.10 (4GB RAM, 2 CPUs)
- worker-1: 192.168.56.11 (6GB RAM, 2 CPUs)
- worker-2: 192.168.56.12 (6GB RAM, 2 CPUs)
```

**Step 2: Shell provisioning scripts run on each VM**
- Disables systemd-resolved and configures DNS (8.8.8.8, 1.1.1.1)
- Tests internet connectivity
- Runs `master-provision.sh` or `worker-provision.sh`

**Step 3: Provision scripts install base requirements**
```bash
# On all nodes:
- Disables swap (Kubernetes requirement)
- Installs containerd runtime + configures SystemdCgroup
- Installs kubeadm, kubelet, kubectl (v1.28)
- Configures kubelet with node IP (--node-ip flag)
- Updates /etc/hosts with all node hostnames
```

**Result:** 3 ready-to-cluster VMs with container runtime and Kubernetes tools

---

### **Phase 2: Kubernetes Cluster Deployment** (`make setup-cluster`)

**Step 1: SSH configuration** (`make ssh-config`)
```bash
# Generates ssh_config from Vagrant for Ansible connectivity
vagrant ssh-config > ssh_config
```

**Step 2: Playbook 00 - Configure Kubelet**
- Sets `KUBELET_EXTRA_ARGS="--node-ip=<NODE_IP>"` on all nodes
- Ensures kubelet advertises the correct private network IP

**Step 3: Playbook 01 - Verify Prerequisites**
- Checks swap is disabled
- Verifies containerd is running
- Confirms kubeadm, kubelet, kubectl are installed
- Validates kernel modules and sysctl settings

**Step 4: Playbook 03 - Initialize Master Node**
```bash
# Runs on master-1:
kubeadm init \
  --apiserver-advertise-address=192.168.56.10 \
  --pod-network-cidr=192.168.0.0/16 \
  --control-plane-endpoint=master-1
```
- Initializes control plane (API server, scheduler, controller-manager, etcd)
- Generates certificates in `/etc/kubernetes/pki/`
- Creates admin kubeconfig in `/etc/kubernetes/admin.conf`
- Copies kubeconfig to vagrant user's `~/.kube/config`

**Step 5: Playbook 04 - Install CNI (Calico)**
```bash
# Downloads and applies Calico manifest
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```
- Deploys Calico pod network for inter-pod communication
- Creates overlay network using VXLAN
- Enables network policies for security

**Step 6: Playbook 05 - Join Worker Nodes**
```bash
# On master, generates join command:
kubeadm token create --print-join-command

# Copies join command to workers and executes:
kubeadm join 192.168.56.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```
- Workers connect to master's API server
- Kubelet on workers registers nodes with cluster
- Workers start accepting pod workloads

**Step 7: Playbook 06 - Verify Cluster**
```bash
kubectl get nodes         # Should show 3 nodes (Ready)
kubectl get pods -A       # Should show all system pods (Running)
```

**Step 8: Playbook 07 - Setup Kubectl Autocomplete**
- Adds bash completion for kubectl commands
- Configures vim syntax highlighting for YAML

**Step 9: Playbook 08 - Install ETCD Client**
- Installs `etcdctl` for backup/restore operations
- Creates helper scripts: `etcd-health`, `etcd-status`

**Result:** Fully functional 3-node Kubernetes cluster with pod networking

---

### **Phase 3: Production Tools Installation** (`make tools`)

**Playbook 09: Install Helm 3**
```bash
# Downloads and installs Helm binary
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

**Playbook 10: Install NGINX Ingress Controller**
```bash
# Deploys NGINX Ingress using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx
```
- Creates LoadBalancer service (uses NodePort in VirtualBox)
- Enables HTTP/HTTPS routing to backend services
- Required for Dashboard, ArgoCD, and VProfile access

**Playbook 11: Setup NFS Server**
```bash
# On master-1:
apt-get install nfs-kernel-server
mkdir -p /srv/nfs/kubedata
echo "/srv/nfs/kubedata *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
systemctl restart nfs-server
```

**Playbook 12: Install NFS Client Provisioner**
```bash
# Deploys NFS provisioner using Helm
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=192.168.56.10 \
  --set nfs.path=/srv/nfs/kubedata
```
- Creates storage class for dynamic PV provisioning
- Applications can request storage via PVCs
- Data persists across pod restarts

**Playbook 13: Install Metrics Server**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Patches for local cluster (--kubelet-insecure-tls)
```
- Collects CPU/memory metrics from kubelets
- Enables `kubectl top nodes` and `kubectl top pods`
- Foundation for HPA (Horizontal Pod Autoscaler)

**Playbook 14: Install Kubernetes Dashboard**
```bash
# Deploys dashboard with Helm
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard
# Creates Ingress with TLS
# Creates ServiceAccount with cluster viewer permissions
```
- Access at: `https://dashboard.yourdomain.com`
- Web UI for viewing cluster resources
- Token-based authentication

**Playbook 15: Install ArgoCD**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Creates Ingress with TLS
```
- GitOps continuous delivery tool
- Monitors Git repo for application manifests
- Automatically syncs desired state to cluster

**Playbook 16: Install ArgoCD CLI**
```bash
# Downloads argocd binary
curl -sSL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -o /usr/local/bin/argocd
chmod +x /usr/local/bin/argocd
```

**Playbook 18: Deploy VProfile via ArgoCD**
```bash
# Creates ArgoCD Application resource pointing to Git repo
kubectl apply -f vprofile-app.yaml
```
- ArgoCD clones repo: `github.com/OchukoWH/argo-project-defs`
- Deploys VProfile namespace with: Nginx, Tomcat, MySQL, Memcached, RabbitMQ
- Creates ingress at: `https://vprofile.yourdomain.com`

**Playbook 19: Setup ETCD Backup Cron**
```bash
# Creates backup script:
/usr/local/bin/etcd-backup.sh

# Adds cron job:
*/2 * * * * /usr/local/bin/etcd-backup.sh >> /var/log/etcd-backup.log 2>&1
```
- Runs every 2 minutes
- Creates snapshot: `/var/backups/etcd/etcd-YYYY-MM-DD_HH-MM-SS.db`
- Deletes backups older than 7 days
- ETCD stores entire cluster state (all resources, secrets, configs)

**Result:** Production-ready cluster with monitoring, storage, ingress, GitOps, and backup

---

### **Phase 4: Access & Verification**

**Access Kubernetes Dashboard:**
```bash
# Get token:
kubectl create token dashboard-viewer-sa -n kubernetes-dashboard

# Open browser: https://dashboard.yourdomain.com
# Paste token for login
```

**Access ArgoCD:**
```bash
# Get password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Open browser: https://argo.yourdomain.com
# Login: admin / <password>
```

**Access VProfile Application:**
```bash
# Open browser: https://vprofile.yourdomain.com
# Login: admin_vp / admin_vp
# Explore multi-tier Java application
```

**Verify ETCD Backups:**
```bash
vagrant ssh master1
sudo ls -lh /var/backups/etcd/
# Should see timestamped .db files created every 2 minutes
```

---

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

## 🎓 Use Cases & Learning Paths

### **👨‍💻 For Kubernetes Beginners**
- **Learn the fundamentals**: Understand pods, services, deployments, and namespaces by interacting with a real cluster
- **Safe experimentation**: Break things and rebuild quickly with `make clean-cluster && make setup-cluster`
- **Visual learning**: Use Kubernetes Dashboard to see how resources relate to each other
- **Hands-on practice**: Deploy your own applications, create ingress rules, configure storage

### **🔧 For DevOps Engineers**
- **Infrastructure as Code mastery**: Study Ansible playbooks to learn automation patterns
- **GitOps workflows**: Practice continuous delivery with ArgoCD watching Git repositories
- **Cluster operations**: Learn backup/restore, node management, troubleshooting
- **Tool integration**: Understand how Helm, Ingress, and storage provisioners work together
- **Portfolio project**: Showcase ability to build production-grade infrastructure from scratch

### **☁️ For Cloud Engineers**
- **Bare-metal understanding**: Learn what managed Kubernetes (EKS/AKS/GKE) abstracts away
- **Cost-effective testing**: Develop and test Kubernetes manifests locally before deploying to expensive cloud resources
- **Multi-cloud preparation**: Skills transfer directly to any Kubernetes environment
- **Networking deep dive**: Understand CNI, service mesh, and ingress concepts

### **📚 For Training & Education**
- **Classroom environments**: Each student can spin up identical clusters
- **Certification prep**: Practice for CKA (Certified Kubernetes Administrator) exam
- **Workshop material**: Use as base for teaching Kubernetes, GitOps, or DevOps concepts
- **Reproducible demos**: Consistently demonstrate complex workflows

### **🧪 For Development Teams**
- **Local testing environment**: Test microservices locally before CI/CD
- **Integration testing**: Verify how services interact in Kubernetes
- **Helm chart development**: Test charts in a real multi-node cluster
- **CI/CD pipeline prototyping**: Develop deployment strategies locally

## 🔬 Technical Deep Dive

### **Why Kubeadm Instead of Managed Kubernetes?**
- **Learning**: See what AWS EKS/Azure AKS abstracts away (control plane setup, certificates, etcd)
- **Flexibility**: Full control over cluster configuration and component versions
- **Cost**: Free for local development vs. cloud control plane costs (~$75/month on AWS)
- **Portability**: Same approach works on bare metal, VMs, or cloud instances

### **Key Technical Concepts Explained**

**1. Control Plane vs. Data Plane**
```
Master Node (Control Plane):
├── kube-apiserver       → API gateway for all cluster operations
├── etcd                 → Distributed key-value store (cluster database)
├── kube-scheduler       → Decides which node runs each pod
├── kube-controller-mgr  → Maintains desired state (deployments, replicasets)
└── cloud-controller-mgr → Integrates with cloud providers (n/a for bare metal)

Worker Nodes (Data Plane):
├── kubelet              → Agent that runs pods on the node
├── kube-proxy           → Network proxy for service discovery
└── containerd           → Container runtime (pulls images, runs containers)
```

**2. Networking Architecture**
```
Layer 1: Physical/VM Network (192.168.56.0/24)
- Master: 192.168.56.10
- Worker1: 192.168.56.11
- Worker2: 192.168.56.12

Layer 2: Pod Network (192.168.0.0/16) - Calico CNI
- Pods get IPs from this range
- Calico creates VXLAN tunnels between nodes
- Enables pod-to-pod communication across nodes

Layer 3: Service Network (10.96.0.0/12)
- Virtual IPs for services (ClusterIP)
- kube-proxy maintains iptables rules for load balancing
- Services provide stable endpoints for pods

Layer 4: Ingress (NGINX)
- HTTP/HTTPS routing (Layer 7)
- TLS termination
- Host-based routing (dashboard.domain.com → Dashboard service)
```

**3. Storage Architecture**
```
Host Storage (Master Node):
/srv/nfs/kubedata/
└── Shared via NFS

NFS Client Provisioner (running in cluster):
├── Watches for PVC (PersistentVolumeClaim)
├── Dynamically creates PV (PersistentVolume)
├── Creates subdirectory on NFS share
└── Mounts it to pod requesting storage

Example Flow:
1. MySQL pod requests 10GB storage via PVC
2. NFS provisioner creates /srv/nfs/kubedata/mysql-pvc-xxx/
3. PV bound to PVC, mounted to MySQL pod at /var/lib/mysql
4. Data persists even if MySQL pod restarts/moves nodes
```

**4. ETCD Backup Strategy**
```
Why ETCD is Critical:
- Stores ALL cluster state (every resource, secret, config)
- Losing ETCD = losing entire cluster configuration
- No ETCD backup = cannot recover from master node failure

Backup Process:
1. etcdctl snapshot save → Creates point-in-time snapshot
2. Snapshot includes: all namespaces, deployments, services, secrets, RBAC
3. Cron runs every 2 minutes → RPO (Recovery Point Objective) = 2 min max data loss
4. 7-day retention → Protect against corruption discovered days later

Restore Process:
1. Stop kube-apiserver (etcd client)
2. Restore snapshot to new directory
3. Update etcd manifest to use new data directory
4. Start kube-apiserver → Cluster state restored
```

**5. GitOps Workflow (ArgoCD)**
```
Traditional Deploy:          GitOps Deploy:
Developer → kubectl apply   Developer → git push
                            └→ ArgoCD detects change
                               └→ ArgoCD applies to cluster

Benefits:
- Git becomes single source of truth
- Audit trail (who changed what, when)
- Easy rollback (git revert)
- Multi-cluster sync (same repo → multiple clusters)
- Self-healing (ArgoCD reverts manual kubectl changes)
```

**6. High Availability Considerations**
```
Current Setup (Single Master):
✅ Good for: Learning, development, testing
❌ Risk: Master failure = cluster down (can't create/modify resources)
✅ Note: Workloads on workers keep running even if master down

Production Setup (HA):
- 3 master nodes (odd number for etcd quorum)
- Load balancer in front of API servers
- External etcd cluster (5 nodes)
- This project can be extended to HA by adding more masters
```

**7. Resource Allocation**
```
System Pods Resource Usage:
- Control plane pods: ~1.5GB RAM
- Calico: ~200MB per node
- CoreDNS: ~100MB
- NGINX Ingress: ~200MB
- Metrics Server: ~50MB
- Dashboard: ~100MB
- ArgoCD: ~500MB

Why Workers Have More RAM:
- Master: Runs control plane (etcd, API server, scheduler)
- Workers: Run application workloads (VProfile, databases, etc.)
- VProfile alone uses: ~2GB (MySQL, Tomcat, Nginx, Memcached, RabbitMQ)
```

**8. Certificate Architecture**
```
/etc/kubernetes/pki/
├── ca.crt / ca.key                    → Cluster CA (signs all certs)
├── apiserver.crt / apiserver.key      → API server TLS cert
├── etcd/
│   ├── ca.crt / ca.key                → ETCD CA
│   ├── server.crt / server.key        → ETCD server cert
│   └── peer.crt / peer.key            → ETCD cluster communication
└── sa.key / sa.pub                    → ServiceAccount signing key

Certificate Validity:
- CA cert: 10 years
- Component certs: 1 year (need renewal)
- kubeadm alpha certs renew all → Renew before expiration
```

---

## 📝 Configuration

- **Hostnames**: master-1, worker-1, worker-2
- **Network**: Private network (192.168.56.0/24)
- **Pod CIDR**: 192.168.0.0/16 (Calico)
- **Service CIDR**: 10.96.0.0/12
- **Ingress**: NGINX (NodePort mode)

## 🤖 Automation Philosophy

### **Why This Project is Fully Automated**

**1. Repeatability**
- Run `make setup-with-tools` → Get identical cluster every time
- No "works on my machine" problems
- Same result whether run once or 100 times

**2. Speed**
- Manual setup: 2-3 hours (following docs, troubleshooting)
- Automated setup: 15-20 minutes (unattended)
- Rebuild cluster in minutes after experimentation

**3. Learning by Doing**
- Read Ansible playbooks to understand what each component does
- Modify playbooks to experiment with different configurations
- Version control tracks what changes break/fix things

**4. Production-Ready Practices**
- Infrastructure as Code (IaC) - Same approach used by enterprises
- Idempotent playbooks - Safe to run multiple times
- Modular design - Each playbook has single responsibility
- Error handling - Playbooks verify prerequisites and check results

**5. Documentation as Code**
- Ansible playbooks are self-documenting
- Each task has descriptive name explaining what it does
- Can trace exactly how cluster was built

### **Makefile: The Single Command Interface**

The `Makefile` provides **25+ commands** organized by lifecycle phase:
```bash
# Setup Phase
make setup              # Create infrastructure
make setup-with-tools   # Full production setup

# Operations Phase  
make verify             # Check cluster health
make etcd-backup        # Configure disaster recovery
make status             # View cluster status

# Tools Phase
make helm               # Install specific tool
make tools              # Install all tools

# Cleanup Phase
make clean-cluster      # Reset Kubernetes (keep VMs)
make clean              # Destroy everything
```

**Benefits:**
- **No memorization needed** - `make help` shows all commands
- **Consistent interface** - Same commands for different environments
- **Chain operations** - `make setup-with-tools` calls multiple targets
- **Easy CI/CD integration** - Scripts can call `make` commands

### **Why 20+ Small Playbooks vs. One Big Playbook?**

**Modularity Benefits:**
```yaml
00-configure-kubelet.yml     # Only touches kubelet config
01-verify-prerequisites.yml  # Only checks requirements
03-init-master.yml           # Only initializes control plane
...
```

**Advantages:**
- **Targeted re-runs**: `make cni` to fix CNI issues without rebuilding cluster
- **Easier debugging**: Small playbook = easy to identify which task failed
- **Selective deployment**: Install only tools you need
- **Learning friendly**: Read one focused playbook at a time
- **Team collaboration**: Multiple people can work on different playbooks
- **Testing**: Test each component independently

### **Real-World Applications**

**This same automation approach scales to:**
- **On-premises data centers**: Replace VirtualBox with physical servers
- **Cloud providers**: Replace Vagrant with Terraform (AWS EC2, Azure VMs)
- **Multi-region deployments**: Add loops to deploy across regions
- **100+ node clusters**: Ansible inventory supports unlimited hosts
- **Hybrid environments**: Mix cloud and on-prem nodes

**Skills Gained Transfer To:**
- AWS EKS/ECS deployments
- Azure AKS management
- GCP GKE operations
- OpenShift administration
- Rancher cluster management

---

## 🔗 Related Projects

- [argo-project-defs](https://github.com/OchukoWH/argo-project-defs) - GitOps application definitions for VProfile and other apps

---

## 📊 Project Statistics

- **20+ Ansible playbooks** - Each handling specific cluster component
- **110+ Ansible tasks** - Automated configuration steps
- **25+ Make targets** - One-command operations
- **3 VMs** - 16GB total RAM, 6 CPUs
- **15-20 minutes** - Complete setup time (fully automated)
- **2-minute RPO** - ETCD backup frequency (disaster recovery)
- **7-day retention** - Backup history for point-in-time recovery

---

**Built by**: [Whoro Ochuko](https://github.com/OchukoWH) 
**Built with**: Vagrant • Ansible • Kubernetes • Helm • ArgoCD • Calico • NFS  
**Perfect for**: Learning, Development, Training, Portfolio, Interviews, CKA Prep  
**License**: Open source - Use, modify, learn from it!

**⭐ Star this project** if you find it helpful for learning Kubernetes!  
**🍴 Fork it** to customize for your own learning path!  
**📝 Open issues** if you have questions or suggestions!
