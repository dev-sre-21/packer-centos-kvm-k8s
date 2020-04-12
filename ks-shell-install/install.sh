#!/usr/bin/env bash
#
set -o errexit
set -o pipefail
#
# description: Sample to install APPs  
# using KickStart and shell script
# version: 0.1
# author: Thiago Fonseca Born da Silva
# e-mail: thiagofborn@gmail.com
#-------------------------------------------------
date=`date`

echo "Installing VI improved"
yum -y install screen vim

echo "Installing Docker"
curl -fsSL https://get.docker.com | bash

echo "Disable SELinux"
# setenforce 0 # it is already defined on the KickStart template as permissive
# Making the change permanent
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "Enable br_netfilter"
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

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

" >> /etc/yum.repos.d/kubernetes.repo

echo "Installing kubelet kubeadm kubectl"
yum install -y kubelet kubeadm kubectl

echo "Restarting the systemd daemon and the kubelet service"
systemctl daemon-reload
systemctl restart kubelet