# 3-Node Kubernetes Infrastructure Setup with Vagrant

This setup creates a 3 node kubernetes cluster using kubeadm with Vagrant VMs. The process is fully automated using Vagrant for provisioning Infrastructure and ansible for automating kubernetes setup.

## ✅ Cluster Status - WORKING!

**Successfully tested and verified:**
- **3 nodes**: master1 (Ready), worker1 (Ready), worker2 (Ready)
- **All system pods**: Running (etcd, kube-apiserver, kube-controller-manager, kube-scheduler, CoreDNS, Calico)
- **Test pod**: Successfully executes "Cluster is working!"
- **API Server**: Accessible and functional
- **Networking**: Calico CNI working across all nodes

## What This Creates

- **1 Master Node** (control plane)
- **2 Worker Nodes** (compute)
- **Vagrant VMs** with Ubuntu 22.04 LTS
- **Private networking** with static IPs for cluster communication
- **Pre-installed Kubernetes packages** (kubelet, kubeadm, kubectl)

## Simple Architecture

```
┌─────────────────────────────────────────┐
│              Vagrant VMs                │
│                                         │
│  ┌─────────────┐  ┌─────────────┐      │
│  │   Master-1  │  │   Worker-1  │      │
│  │ (Control    │  │  (Compute   │      │
│  │  Plane)     │  │   Node)     │      │
│  │192.168.56.10│  │192.168.56.11│      │
│  └─────────────┘  └─────────────┘      │
│                                         │
│  ┌─────────────┐                       │
│  │   Worker-2  │                       │
│  │  (Compute   │                       │
│  │   Node)     │                       │
│  │192.168.56.12│                       │
│  └─────────────┘                       │
└─────────────────────────────────────────┘
```

## Prerequisites

1. **Vagrant** >= 2.0 installed
2. **VirtualBox** or other Vagrant provider
3. **Make** utility installed (for automation)
4. **Ansible** installed (for cluster setup)
5. **At least 6GB RAM** available for VMs

### Installation Instructions

**macOS:**
```bash
# Install Vagrant, VirtualBox, and Ansible
brew install vagrant virtualbox ansible
```

**Ubuntu/Debian:**
```bash
# Install Vagrant, VirtualBox, Make and Ansible
sudo apt update
sudo apt install vagrant virtualbox make ansible
```

**CentOS/RHEL:**
```bash
# Install Vagrant, VirtualBox, Make and Ansible
sudo yum install vagrant VirtualBox make ansible
# or for newer versions:
sudo dnf install vagrant VirtualBox make ansible
```

## Quick Start with Makefile

The easiest way to set up the entire cluster:

```bash
# One command setup (recommended)
make setup

# Or step by step:
make setup-vagrant          # Complete VM setup (create VMs + install tools + inventory)
make setup-cluster          # Complete cluster setup

# Or individual steps:
make up                     # Start Vagrant VMs
make inventory              # Create inventory file
make all                    # Deploy Kubernetes cluster
```

## Complete Setup Workflow

### 1. VM Setup
```bash
make setup-vagrant
```
**What this does:**
- Starts Vagrant VMs (3 VMs with Ubuntu 22.04)
- Provisions VMs with Kubernetes tools (kubelet, kubeadm, kubectl)
- Creates Ansible inventory file (`hosts.yml`) with Vagrant IPs

**VMs created:**
- Master: `192.168.56.10`
- Worker1: `192.168.56.11`
- Worker2: `192.168.56.12`

### 2. Cluster Setup
```bash
make setup-cluster
```
**What this does:**
- Runs all Ansible playbooks to deploy Kubernetes
- Verifies prerequisites
- Configures kubelet node IPs
- Initializes master node
- Installs CNI (Calico)
- Joins worker nodes
- Verifies cluster is working

### 3. Cluster Cleanup (when done)
```bash
make cleanup-cluster
```
**What this does:**
- Runs `kubeadm reset -f` on all nodes
- Removes `.kube/config` from master node
- Fast cleanup without uninstalling packages

### 4. Complete Cleanup
```bash
make clean
```
**What this does:**
- First runs `cleanup-cluster` (see above)
- Then removes local files (inventory, logs)
- Destroys all Vagrant VMs

### Available Makefile Targets

```bash
make help                   # Show all available commands
make setup                  # Complete setup (VMs + cluster) in one command ⭐
make up                     # Start Vagrant VMs
make down                   # Stop Vagrant VMs
make provision              # Provision VMs with Kubernetes tools
make inventory              # Create inventory file
make ping                   # Test connectivity
make ssh-config             # Generate SSH config for Ansible
make prereq                 # Run prerequisites
make kubelet                # Configure kubelet node IPs
make master                 # Initialize master
make cni                    # Install CNI
make workers                # Join workers
make verify                 # Verify cluster
make setup-vagrant          # Complete VM setup
make setup-cluster          # Complete cluster setup
make cleanup-cluster        # Clean up Kubernetes resources
make clean                  # Clean up files and destroy VMs
make status                 # Check cluster status
```

## Configuration

### Variables (Vagrantfile)

- `MASTER_IP`: Master node IP (default: 192.168.56.10)
- `WORKER1_IP`: Worker node 1 IP (default: 192.168.56.11)
- `WORKER2_IP`: Worker node 2 IP (default: 192.168.56.12)

### Customization

Edit `Vagrantfile` to customize:
- Instance IPs
- VM memory/CPU
- Kubernetes version (in provisioning scripts)

## Post-Deployment - Setting Up Kubernetes with kubeadm

After `make setup-vagrant` completes, you'll have 3 Vagrant VMs ready for Kubernetes setup:

1. **SSH to master node:**
   ```bash
   vagrant ssh master1
   ```

2. **Initialize Kubernetes cluster:**
   ```bash
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16
   ```

3. **Configure kubectl:**
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

4. **Install CNI (Calico):**
   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

5. **Get join command for worker nodes:**
   ```bash
   sudo kubeadm token create --print-join-command
   ```

6. **SSH to worker nodes and join cluster:**
   ```bash
   vagrant ssh worker1
   sudo <join-command-from-step-5>
   ```

7. **Verify cluster:**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

## Automated Setup with Ansible

For automated cluster setup, you can use the provided Ansible playbooks:

### Prerequisites
1. **Install Ansible:**
   ```bash
   pip install ansible
   ```

2. **Update inventory file:**
   The `cluster-setup/inventory/hosts.yml` file is automatically created by `make setup-vagrant`.

3. **Test connectivity:**
   ```bash
   ansible all -m ping
   ```

### Run Individual Playbooks

1. **Configure kubelet node IPs:**
   ```bash
   ansible-playbook cluster-setup/playbooks/00-configure-kubelet.yml
   ```

2. **Verify prerequisites:**
   ```bash
   ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml
   ```

3. **Initialize master node:**
   ```bash
   ansible-playbook cluster-setup/playbooks/03-initi-master.yml
   ```

4. **Install CNI (Calico):**
   ```bash
   ansible-playbook cluster-setup/playbooks/04-install-cni.yml
   ```

5. **Join worker nodes:**
   ```bash
   ansible-playbook cluster-setup/playbooks/05-join-workers.yml
   ```

6. **Verify cluster:**
   ```bash
   ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
   ```

7. **Setup kubectl autocomplete:**
   ```bash
   ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml
   ```

### Run Playbooks with Verbose Output
```bash
ansible-playbook cluster-setup/playbooks/01-verify-Prerequisites.yml -v
```

### Expected Cluster Status After Setup
After running all playbooks, you should see:
- **3 nodes**: master1 (Ready), worker1 (Ready), worker2 (Ready)
- **All system pods**: Running (etcd, kube-apiserver, kube-controller-manager, kube-scheduler, CoreDNS, Calico)
- **Test pod**: Successfully executes "Cluster is working!"
- **API Server**: Accessible at `https://<master-ip>:6443`

### Troubleshooting Ansible
- **Check inventory:** `ansible all -m ping`
- **Test specific group:** `ansible masters -m ping`
- **View logs:** Check `ansible.log` file

## Network Configuration

- **Master**: SSH (22), Kubernetes API (6443), etcd (2379-2380), kubelet (10250)
- **Workers**: SSH (22), kubelet (10250), NodePort (30000-32767)
- **Private Network**: 192.168.56.0/24 for cluster communication

This setup is perfect for practicing:

- **kubeadm cluster initialization**
- **Node management and troubleshooting**
- **Pod networking and CNI configuration**
- **Security contexts and RBAC**
- **Service and ingress configuration**
- **Persistent volumes and storage**
- **Cluster maintenance and upgrades**

## Cleanup Workflow

### Complete Cleanup (Recommended)

To properly clean up everything:

```bash
# 1. Clean up Kubernetes resources from VMs + local files
make clean
```

### Individual Cleanup Steps

```bash
# Clean up Kubernetes resources from VMs only
make cleanup-cluster

# Clean up local files only (inventory, logs)
make clean

# Destroy Vagrant infrastructure only
make clean-infra
```

### What Each Cleanup Command Does:

**`make cleanup-cluster`:**
1. Runs `kubeadm reset -f` on all nodes to clean up cluster state
2. Removes `.kube/config` from master node
3. Fast cleanup without uninstalling packages

**`make clean`:**
- First runs `cleanup-cluster` (see above)
- Then removes local files (inventory, logs)
- Destroys all Vagrant VMs

## Troubleshooting

### Common Issues and Solutions

#### 1. **Provisioning Failures**
If `make provision` fails with GPG key errors:
```bash
# Clean up and retry
make clean-infra
make setup-vagrant
```

#### 2. **Cluster Setup Failures**
If `make setup-cluster` fails:
```bash
# Check if VMs are running
vagrant status

# Regenerate SSH config (common fix)
make ssh-config

# If VMs are running but cluster setup fails, clean cluster and retry
make clean-cluster
make setup-cluster
```

#### 3. **kubelet Service Not Found**
If you get "Could not find the requested service kubelet":
- This happens after running `make clean-cluster`
- Run `make provision` first to reinstall Kubernetes tools
- Then run `make setup-cluster`

#### 4. **Worker Nodes Not Joining**
If worker nodes fail to join:
- Check that the master node is fully initialized
- Verify the join command uses the correct IP (192.168.56.10)
- Check network connectivity between nodes

#### 5. **SSH Connectivity Issues (Most Common)**
If you get "Permission denied (publickey,password)" or "UNREACHABLE!" errors:
```bash
# This is usually a timing issue - SSH config needs regeneration
make ssh-config

# Test connectivity
ansible all -m ping

# If still failing, manually regenerate:
vagrant ssh-config > ssh_config
```

**Why this happens:** During `vagrant up`, SSH keys are generated and network interfaces are configured. Ansible needs the updated SSH config to connect properly.

#### 6. **General Troubleshooting Commands**
```bash
# Check Kubernetes status
vagrant ssh master1 -c "kubectl get nodes"
vagrant ssh master1 -c "kubectl get pods -A"

# Check VM status
vagrant status

# View VM logs
vagrant ssh master1
vagrant ssh worker1
vagrant ssh worker2
```

### Workflow Best Practices

#### **First Time Setup:**
```bash
make setup-vagrant    # Create VMs and install tools
make setup-cluster    # Deploy Kubernetes cluster
```

#### **Reset Cluster (Keep VMs):**
```bash
make clean-cluster    # Reset cluster state
make setup-cluster    # Deploy new cluster
```

#### **Complete Reset:**
```bash
make clean           # Destroy everything and start fresh
make setup-vagrant   # Create new VMs
make setup-cluster   # Deploy new cluster
```

### Cleanup Options

- **`make clean-cluster`**: Fast reset - only runs `kubeadm reset -f` and removes kubectl config
- **`make clean-infra`**: Destroys all VMs
- **`make clean`**: Complete cleanup (cluster + infrastructure + files)


