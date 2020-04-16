#!/usr/bin/env bash
#
set -o errexit
set -o pipefail
#
# description: Sample to install Docker and 
# Kubernetes using KickStart and shell script
# version: 0.1
# author: Thiago Fonseca Born da Silva
# e-mail: thiagofborn@gmail.com
#-------------------------------------------------
date=`date`

echo "Tools"
yum -y install tmux screen vim bind-utils

echo "Disable and Stop FirewallD"
systemctl stop firewalld
systemctl disable firewalld

echo "Disable SELinux"
# setenforce 0 # it is already defined on the KickStart template as permissive
# Making the change permanent
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "Setting up network definitions $date | "
echo "
#--------------------------------------------------------------------------------
# Adding Iptables settings $date |
#--------------------------------------------------------------------------------
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1

" >> /etc/sysctl.d/k8s.conf

# Load the changes
sysctl --system

echo "Installing Docker"
# Install Docker CE
## Set up the repository
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum update -y && yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.8 \
  docker-ce-cli-19.03.8

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker

echo "Enabling Docker will run during the boot"
systemctl enable docker

echo "Check cgroup Docker and kubelet, output must be: Cgroup Driver: cgroupfs"
docker info | grep -i cgroup > /root/cgroup_check.log

echo "Adding Kubernetes Official repository $date | "
echo "
#--------------------------------------------------------------------------------
# Adding Kubernetes Official repository $date |
#--------------------------------------------------------------------------------
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

" >> /etc/yum.repos.d/k8s.repo

echo "Installing kubelet kubeadm kubectl"
yum install -y kubelet kubeadm kubectl

echo "Restarting the systemd daemon and the kubelet service and set to run kubelet during the boot"
systemctl daemon-reload
systemctl enable kubelet
