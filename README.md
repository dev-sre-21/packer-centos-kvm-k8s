# Deploy Kubernetes cluster using Packer and Kickstart - Centos hands-on

>PLEASE NOTE: This is a work in progress. We will take some decisions to keep this a bit "hard" and "old school".

## Contents

<!-- TOC -->

- [Deploy Kubernetes cluster using Packer and Kickstart - Centos 7.x hands-on lab](#deploy-kubernetes-cluster-using-packer-and-kickstart---centos-7.x-hands-on-lab)
  - [Abstract and learning objectives](#abstract-and-learning-objectives)
  - [Overview](#overview)
  - [Solution architecture](#solution-architecture)
  - [Requirements](#requirements)
  - [Main task 1: Installing Packer](#installing-packer)
    - [Task 1: Setting up your local environment to run Packer](#setting-up-your-local-environment-to-run-packer)
    - [Task 2: xxxxx](#task-2-browsing-to-the-web-application)
    - [Task 3: xxxxx](#task-3-create-a-dockerfile)
  - [Main task 2: xx](#exercise-2-deploy-the-solution-to-azure-kubernetes-service)
    - [Task 1: xxxxx](#task-1-tunnel-into-the-azure-kubernetes-service-cluster)
    - [Task 2: xxxxx](#task-2-deploy-a-service-using-the-kubernetes-management-dashboard)
  - [Exercise 3: xxx](#exercise-3-scale-the-application-and-test-ha)
    - [Task 1: xxxxx](#task-1-increase-service-instances-from-the-kubernetes-dashboard)
  - [Exercise 4: xxx](#exercise-4-working-with-services-and-routing-application-traffic)
    - [Task 1: xxxxx](#task-1-scale-a-service-without-port-constraints)
    - [Task 2: Update an external service to support dynamic discovery with a load balancer](#task-2-update-an-external-service-to-support-dynamic-discovery-with-a-load-balancer)
    - [Task 3: xxxxx](#task-3-adjust-cpu-constraints-to-improve-scale)
  - [After the hands-on lab](#after-the-hands-on-lab)

<!-- /TOC -->

## Abstract and learning objectives

This hands-on lab is designed to guide you through the process of building and deploying a Kubernetes Cluster using Packer and KickStart. This document is under development, and some commands and details are being added without a proper organization. Things like: commands for Kubernetes, KVM administration using *virsh* will be spread all around. (service scale-out, and high-availability, monitoring and trancing, will be the next project). This is not an up to date best practice for provisioning.

## Overview

The document explain how to launch a Kubernetes cluster with three nodes, via command line using Packer and KickStart. 

Packer is an application created by Hashicorp, that makes use of templates in JSON format. The Packer's template has the instructions to download the operating system image, specifications regarding the virtual machine, and as optional definition a post-install script.

KickStart takes place to manage the virtual machine definitions in a fine-grained manner. For instance, how the virtual machine disk should be partitioned, unnecessary firmware removal, disabling services from *systemd*. KickStart has numerous variety of use. To learn more: <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user>

This overview is an example that depicts how to create infrastructure during a phase of transition. This model was standard during the transformation between the *past view* that I call "the system admin phase" and the evolution of pipelines focused on "deliver what the developers need."

## Solution architecture

One host computer with a Linux distribution RedHat based distribution, to create three virtual machines, each one will be a node of the Kubernetes cluster.
For this lab, I have used Fedora, and for the KVM guests are CentOS.

<img src="https://github.com/dev-sre-21/packer-centos-kvm-k8s/blob/master/media/simply-schema.png?raw=true" width="350" height="350">

## Requirements

Let's simplify the context in *software* and *hardware* requirements.

- Software:

1. Packer <https://packer.io/downloads.html>
2. KVM <https://www.linux-kvm.org/page/Main_Page>
3. KickStart <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax>

Packer: file related *centos7-k8s-base.json*<br\>
KVM: file related *TODO* (shell script to launch the vms for testing)<br\>
KickStart: file related *c7-kvm-k8s.cfg*<br\>

- Hardware:

1. HD Free space around 15 giga: considering the three VMs that will host Master, the two K8s Nodes.
2. RAM around 8 Giga

## Installing Packer

From the hypervisor. Go to <https://releases.hashicorp.com/packer/>, find the latest release (some say this is the best practice).
Download it and unzip.

Example using curl and unzip:

```sh
curl -LO https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip
unzip packer_1.5.5_linux_amd64.zip
```

>Notice: Because the packer is already compiled, it is a good practice to verify if the file was perfectly downloaded.

Hashicorp provides hash (using Secure Hash Algorithm 256) files that you can use to verify your download.
So you can download the files as follows:

Example:

```sh
curl -Os https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_SHA256SUMS
curl -Os https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_SHA256SUMS.sig
# This one below we don't need because we have downloaded it before
# curl -Os https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip
# Verify the signature file is untampered.
# To create the hashicorp.asc go to <https://www.hashicorp.com/security.html>
# Get the "-----BEGIN PGP PUBLIC KEY BLOCK-----" until the "-----END PGP PUBLIC KEY BLOCK-----"
# clean the empty spaces and save the file as hashicorp.asc.
# Then import the file as follows:
```

Learn more at: <https://www.hashicorp.com/security/>

We can find the PGP going to the end of the page.

<img src="https://github.com/dev-sre-21/packer-centos-kvm-k8s/blob/master/media/hashicorp_pgp.png?raw=true" width="350" height="350">

```sh
gpg --import hashicorp.asc
gpg --verify packer_1.5.5_SHA256SUMS.sig packer_1.5.5_SHA256SUMS
```

In case you get a *Warning* like follows. We are on the same boat.

```text
born # gpg --import hashicorp.asc
gpg: key 51852D87348FFC4C: public key "HashiCorp Security <security@hashicorp.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
born # gpg --verify packer_1.5.5_SHA256SUMS.sig packer_1.5.5_SHA256SUMS
gpg: Signature made Wed Mar 25 22:43:34 2020 GMT
gpg:                using RSA key 91A6E7F85D05C65630BEF18951852D87348FFC4C
gpg: Good signature from "HashiCorp Security <security@hashicorp.com>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 91A6 E7F8 5D05 C656 30BE  F189 5185 2D87 348F FC4C
```

Take a look at:

<https://github.com/hashicorp/packer/issues/8745>

Verify the SHASUM matches the binary.

```sh
shasum -a 256 -c packer_1.5.5_SHA256SUMS
```

## Setting up your local environment to run Packer

After the download and verifications. We can **move** or **copy** the *packer binary*, to a proper location that is visible from your execution PATH variable at your operating system, like: */usr/local/bin*.

## Clone the repository

## Set your own variables

## Launch your KVM guest

## Commands and annotations

## My stuff bellow, I will delete it in the future and add somewhere else

## TODO

Setup the VM's configuration automatically.

1. Set the hostnames accordingly
2. Set up the K8s Master
3. Set up the log rotation <https://kubernetes.io/docs/concepts/cluster-administration/logging/>
4. Write a app to maintain the log transference based on the IO operations
5. Add user and set the home directory

Fix the index README.md
systemctl start docker
yum install -y kubelet kubeadm kubectl (Kickstart has failed. ?)
Kickstart missing ? (systemctl enable kubelet && systemctl start kubelet)
docker info | grep -i cgroup

kubeadm init --apiserver-advertise-address 192.168.100.170
kubeadm config images pull (e nao deixa passar nome só IP?)

After:

```sh
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Packer template:

>Values to notice: "disk_size": "10000", it is in mbytes.
It is around 10 gigabytes.

List and Shutdown guest VM KVM command line

```sh
sudo virsh list # it will show the guests running, to list all the guests add --all at the end
sudo virsh shutdown 11 --mode acpi
```

Getting the guest's IP address

*default* here is the network name

```sh
sudo virsh net-list # Get the network name
sudo virsh net-dhcp-leases default
```

Check the possible --os-variant OS

```sh
osinfo-query os | grep centos
```

Creating VM command line

After the image get done we have the results written at:

```text
The disk:
./centos7-k8s-base-img/centos7-k8s-base
```

And

```text
The downloaded ISO
./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso
```

So, to create the KVM guest we need to add this paths to the command line composition as follows:

> Notice: Plus the VM name.

```sh
# check if you have enough space
df -h . | tail -1 | awk '{print $4}'
echo "You should have at least 30G"
# lazyness: copying the main image to other vms
# keeping the orginal for future updates
sudo cp ./centos7-k8s-base-img/centos7-k8s-base ./centos7-k8s-kvm-imgs/centos7-k8s-base-1
sudo cp ./centos7-k8s-base-img/centos7-k8s-base ./centos7-k8s-kvm-imgs/centos7-k8s-base-2
sudo cp ./centos7-k8s-base-img/centos7-k8s-base ./centos7-k8s-kvm-imgs/centos7-k8s-base-3

USER=qemu
GROUP=qemu
sudo chown -R $USER:$GROUP /books/deployment/packer/kvm/packer-centos-kvm-k8s/centos7-k8s-kvm-imgs

VM="centos-kvm-k8s-01"
DISK="./centos7-k8s-kvm-imgs/centos7-k8s-base-1"
ISO="./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso"
sudo virt-install --import --name $VM --memory 2048 --vcpus 2 --cpu host --disk $DISK,format=qcow2,bus=virtio --disk $ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --os-variant=centos7.0 --graphics spice --noautoconsole

# Changed the DISK variable to point to the copy of centos7-k8s-base
VM="centos-kvm-k8s-02"
DISK="./centos7-k8s-kvm-imgs/centos7-k8s-base-2"
ISO="./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso"
sudo virt-install --import --name $VM --memory 2048 --vcpus 2 --cpu host --disk $DISK,format=qcow2,bus=virtio --disk $ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --os-variant=centos7.0 --graphics spice --noautoconsole

VM="centos-kvm-k8s-03"
DISK="./centos7-k8s-kvm-imgs/centos7-k8s-base-3"
ISO="./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso"
sudo virt-install --import --name $VM --memory 2048 --vcpus 2 --cpu host --disk $DISK,format=qcow2,bus=virtio --disk $ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --os-variant=centos7.0 --graphics spice --noautoconsole
```

## Snapshot images and revert to previous state

```sh
# Snapshot the images in case you want to get back to the previous state
sudo virsh snapshot-create-as --domain "centos-kvm-k8s-01" --name centos-kvm-k8s-01_state_0
# Revert to the previous state
sudo virsh snapshot-revert --domain "centos-kvm-k8s-01" --snapshotname centos-kvm-k8s-01_state_0 --running
# To list snapshots
virsh snapshot-list --domain "centos-kvm-k8s-01"
```

- References

- Push to master -  <https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>

When git completes, ssh-agent terminates, and the key is forgotten.

```sh
ssh-agent bash -c 'ssh-add ~/.ssh/packer-centos7-kvm-k8s; git push git@github.com:dev-sre-21/packer-centos-kvm-k8s.git'
```

## I need to think about

adduser born  OR    echo "born:x:1000:1000::/home/born:/bin/bash" >> /etc/passwd
passwd born   OR    echo "born:$6$PqOMZg/D$o0qQqJs9tBsWrHerTMRsXqyU1sUPqwDZja1rF5/Z4zXp40T/ukrZjCCt0oP1R4u5u0KHsTkFSpzcYq6Ra9SP4/:18368:0:99999:7:::" >> /dev/shadow

echo "born    ALL=(ALL)       ALL" >> /etc/sudoers
grep born /etc/sudoers

hostnamectl set-hostname centos-kvm-k8s-03
usermod -aG docker born

## Add this on kickstart post-install script

I need to get back here and think a bit about it.

```sh
ip_dhcp_lease=$(ip a  show dev eth0  | grep -o -E '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' | head -1)
echo "$ip_dhcp_lease  $(hostname)" >> /etc/hosts
```

```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R  $(id -u):$(id -g) $HOME/.kube/config
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --kubeconfig ~/.kube/config
```

## Two stages

First for Master node then Worker nodes?

Workers nodes

```sh
kubeadm join 192.168.100.245:6443 --token 0zor7p.2z5zs0hbpms1299z --discovery-token-ca-cert-hash sha256:4587252951dd3507a81325eed15926d355527746cfc8d0c7cda1f648ea8e7666
```

## Install Helm

"Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application.
Charts are easy to create, version, share, and publish — so start using Helm and stop the copy-and-paste.

The latest version of Helm is maintained by the CNCF - in collaboration with Microsoft, Google, Bitnami and the Helm contributor community.
Helm's default list of public repositories is initially empty. Now let's add the Google chart repo, and start using it."

>Quoted from: <https://v2.helm.sh/>

```sh
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

## Install Helm repository

```sh
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

Verify the repository added.

```sh
helm search repo redis
```

The command should output:

```text
NAME    URL
stable  https://kubernetes-charts.storage.googleap
```

The Helm command defaults to discovering the host already set in ~/.kube/config. It is possible to change or override the host.
The next step gets right to it by installing a pre-made chart.

```sh
kubectl -n kube-system create serviceaccount tiller
```

```sh
kubectl create clusterrolebinding tiller \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller
```

```sh
helm init --service-account tiller
```

```sh
# Users in China: You will need to specify a specific tiller-image in order to initialize tiller. 
# The list of tiller image tags are available here: https://dev.aliyun.com/detail.html?spm=5176.1972343.2.18.ErFNgC&repoId=62085. 
# When initializing tiller, you'll need to pass in --tiller-image

helm init --service-account tiller \
--tiller-image registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:<tag>
```