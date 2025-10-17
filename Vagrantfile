# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Global settings
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.3.12"

  # Use default SSH key (so  works)
  config.ssh.insert_key = true

  # Define IP addresses for the cluster
  MASTER_IP = "192.168.56.10"
  WORKER1_IP = "192.168.56.11"
  WORKER2_IP = "192.168.56.12"

  # Master Node
  config.vm.define "master1" do |master|
    master.vm.hostname = "3-nodes-k8s-cluster-master-1"
    master.vm.network "private_network", ip: MASTER_IP

    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "3-nodes-k8s-cluster-master-1"
    end

    # Provision master node
    master.vm.provision "shell", inline: <<-SHELL
      # Fix DNS resolution
      systemctl disable systemd-resolved
      systemctl stop systemd-resolved
      rm -f /etc/resolv.conf
      echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

      # Test internet connectivity
      if ! ping -c 4 google.com > /dev/null 2>&1; then
        echo "No internet resolution"
        exit 1
      fi

      echo "Internet OK, continuing with master setup..."
    SHELL

    master.vm.provision "shell", path: "scripts/master-provision.sh", args: ["3-nodes-k8s-cluster", "1", MASTER_IP]
  end

  # Worker Node 1
  config.vm.define "worker1" do |worker|
    worker.vm.hostname = "3-nodes-k8s-cluster-worker-1"
    worker.vm.network "private_network", ip: WORKER1_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "3-nodes-k8s-cluster-worker-1"
    end

    worker.vm.provision "shell", inline: <<-SHELL
      # Fix DNS resolution
      systemctl disable systemd-resolved
      systemctl stop systemd-resolved
      rm -f /etc/resolv.conf
      echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

      # Test internet connectivity
      if ! ping -c 4 google.com > /dev/null 2>&1; then
        echo "No internet resolution"
        exit 1
      fi

      echo "Internet OK, continuing with worker setup..."
    SHELL

    worker.vm.provision "shell", path: "scripts/worker-provision.sh", args: ["3-nodes-k8s-cluster", "1", WORKER1_IP]
  end

  # Worker Node 2
  config.vm.define "worker2" do |worker|
    worker.vm.hostname = "3-nodes-k8s-cluster-worker-2"
    worker.vm.network "private_network", ip: WORKER2_IP

    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "3-nodes-k8s-cluster-worker-2"
    end

    worker.vm.provision "shell", inline: <<-SHELL
      # Fix DNS resolution
      systemctl disable systemd-resolved
      systemctl stop systemd-resolved
      rm -f /etc/resolv.conf
      echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

      # Test internet connectivity
      if ! ping -c 4 google.com > /dev/null 2>&1; then
        echo "No internet resolution"
        exit 1
      fi

      echo "Internet OK, continuing with worker setup..."
    SHELL

    worker.vm.provision "shell", path: "scripts/worker-provision.sh", args: ["3-nodes-k8s-cluster", "2", WORKER2_IP]
  end

  # Post-provisioning: Update /etc/hosts on all nodes
  config.vm.provision "shell", inline: <<-SHELL, run: "always"
    echo "#{MASTER_IP} master1 3-nodes-k8s-cluster-master-1" >> /etc/hosts
    echo "#{WORKER1_IP} worker1 3-nodes-k8s-cluster-worker-1" >> /etc/hosts
    echo "#{WORKER2_IP} worker2 3-nodes-k8s-cluster-worker-2" >> /etc/hosts
  SHELL
end

