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
    - [Task 1: Verify Packer Downlaod](#verify-packer-download)
    - [Task 2: Setting up your local environment to run Packer](#setting-up-your-local-environment-to-run-packer)
    - [Task 3: Clone the repository](#clone-the-repository)
  - [Main task 1: Setup your variables](#setup-your-variables)
    - [Task 1: Execute Packer](#execute-packer)
    - [Task 2: Observe the logs](#observe-the-logs)
    - [Task 3: Observe via VNC the OS console](#observe-via-vnc-the-os-console)
  - [Exercise 3: Launch your KVM guests](#launch-your-kvm-guests)
    - [Task 1: Keeping the orginal image for future updates](#keeping-the-orginal-image-for-future-updates)
  - [Exercise 4: Setup the images](#setup-the-images)
    - [Task 1: List guest IP](#list-guest-ip)
    - [Task 2: Set hostname on the virtual machines](#set-hostname-on-the-virtual-machines)
  - [After the hands-on lab](#after-the-hands-on-lab)

<!-- /TOC -->

## Abstract and learning objectives

This hands-on lab is designed to guide you through the process of building and deploying a Kubernetes Cluster using Packer and KickStart on a KVM Hypervisor. This document is under development, and some commands and details are being added without a proper organization. Things like: commands for Kubernetes, KVM administration using *virsh* will be spread all around. (service scale-out, and high-availability, monitoring and trancing, will be the next project). This is not an up to date best practice for provisioning.

## Overview

The document explain how to launch a Kubernetes cluster with three nodes, via command line using Packer and KickStart.

Packer is an application created by Hashicorp that makes use of templates in JSON format to provision operating system images. The Packer's template has the instructions to download the operating system image and specifications regarding the virtual machine resources. Additionally, the template can have directives pointing to post-install scripts. The post-install scripts can be used to change configurations files or to install new applications to the operating system image. In short, if you want to have an HTTP server (Apache or NGINX), it is possible to add this to the post-install script. The scrip will run during the provisioning state and be added to the operating system image at the end.

KickStart takes place to manage the virtual machine definitions in a fine-grained manner. For instance, how the virtual machine disk should be partitioned, unnecessary firmware removal, disabling services from *systemd*. KickStart has numerous variety of use. To learn more please go to: [KickStart - RedHat reference](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-commands-and-options-reference_installing-rhel-as-an-experienced-user)

This overview is an example that depicts how to create infrastructure during a "transition phase." This model was standard during the transformation between the *past techniques* that I call "the system admin phase" and the evolution of pipelines focused on "deliver what the developers need.", via code and operations.

## Solution architecture

One host computer with a Linux RedHat based distribution, to create three virtual machines, each one will be a node of the Kubernetes cluster.
For this lab, I have used Fedora, and for the KVM guests CentOS.

<p align="center">
  <img width="350" height="350" src="https://github.com/dev-sre-21/packer-centos-kvm-k8s/blob/master/media/simply-schema.png?raw=true">
</p>

## Requirements

Let's simplify the context in *software* and *hardware* requirements.

- Software:

1. Packer <https://packer.io/downloads.html>
2. KVM <https://www.linux-kvm.org/page/Main_Page>
3. KickStart <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax>

- Packer: file related *centos7-k8s-base.json*
- KVM: file related *TODO* (shell script to launch the vms for testing)
- KickStart: file related *c7-kvm-k8s.cfg*

- Hardware:

1. HD Free space around 15 Giga: considering the three VMs, we will have one Master node and two K8s worker nodes
2. Around 8 Giga free RAM. So each vm will get 2 Giga RAM (6 Giga RAM in total). I am considering to leave 2 Giga of RAM to the Host Operting System (hypervisor)

## Installing Packer

From the hypervisor. Go to <https://releases.hashicorp.com/packer/>, find the latest release (some say this is the best practice).
Download it and unzip.

Example using curl and unzip:

```sh
curl -LO https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip 
unzip packer_1.5.5_linux_amd64.zip
```

## Verify Packer download

>Notice: Because the packer is already compiled, it is a good practice to verify if the file was perfectly downloaded.

Hashicorp provides hash (using Secure Hash Algorithm 256) files that you can use to verify your download.
So you can download the files as follows:

```sh
curl -Os https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_SHA256SUMS
curl -Os https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_SHA256SUMS.sig
# This one below we don't need because we have downloaded it before
# curl -Os https://releases.hashicorp.com/packer/1.5.5/packer_1.5.5_linux_amd64.zip
# Verify the signature file is untampered. In order to do this you will need to create a public key.
#
# To create the public key as: hashicorp.asc go to <https://www.hashicorp.com/security.html>
# Get the "-----BEGIN PGP PUBLIC KEY BLOCK-----" until the "-----END PGP PUBLIC KEY BLOCK-----"
# Then clean the empty spaces and save the file as hashicorp.asc.
# Then import the file as follows:
```

Learn more at: <https://www.hashicorp.com/security/>

> Please note: We can find the PGP going to the end of the page. And the file should be like the picture.
One blank line bellow the line **-----BEGIN PGP PUBLIC KEY BLOCK-----** and no empty lines or blank spaces until the end.

<img src="https://github.com/dev-sre-21/packer-centos-kvm-k8s/blob/master/media/hashicorp_pgp.png?raw=true" width="350" height="350">

## Importing the public GPG key to your environment

The first command import and the second command verifies the signature from the file.

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

```sh
clone https://github.com/dev-sre-21/packer-centos-kvm-k8s.git
```

## Setup your variables

Open the file *centos7-k8s-base.json* and set the variables iso and *checksum* accordingly. In short, pick a url ISO near to your location for the sake of a low latency network.

```json
{
  "variables": {
    "iso": "http://centos.mirror.garr.it/centos/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso",
    "checksum": "9a2c47d97b9975452f7d582264e9fc16d108ed8252ac6816239a3b58cef5c53d"
  },
```

## Execute Packer

```sh
packer build centos7-k8s-base.json
```

## Observe the logs

This step is **optional**. During the packer build.

## Observe via VNC the OS console

This step is **optional**. It is possible to connect via vnc to the hypervisor and see the VM actions.

<img src="https://github.com/dev-sre-21/packer-centos-kvm-k8s/blob/master/media/packer_wait_ssh.png?raw=true" width="600" height="300">

>Please note the line: **qemu: vnc://127.0.0.1:5959**

## Launch your KVM guests

So, to create the KVM guest we need to add this paths to the command line composition as follows:

>Plese note: check if you have enough space

So, you can use a VNC cliente and check what is going on during the virtual machine installation.

```sh
df -h . | tail -1 | awk '{print $4}'
echo "You should have at least 30G"
```

## Keeping the orginal image for future updates

Here we are making a copy of the image for each virtual machine we will use.
This way we can keep the orginal image and update it as needed without touch on the virtual machine images.

```ssh
sudo cp ./centos7-k8s-base-img/centos7-k8s-base ./centos7-k8s-kvm-imgs/centos7-k8s-base-1
sudo cp ./centos7-k8s-base-img/centos7-k8s-base ./centos7-k8s-kvm-imgs/centos7-k8s-base-2
sudo cp ./centos7-k8s-base-img/centos7-k8s-base ./centos7-k8s-kvm-imgs/centos7-k8s-base-3
```

## Setup the images

Change the images owner to qemu, so the virtual machines will be created.

```ssh
USER=qemu
GROUP=qemu
sudo chown -R $USER:$GROUP /books/deployment/packer/kvm/packer-centos-kvm-k8s/centos7-k8s-kvm-imgs
```

Launch the virtual machines (three in total)

```sh
VM="centos-kvm-k8s-01"
DISK="./centos7-k8s-kvm-imgs/centos7-k8s-base-1"
ISO="./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso"
sudo virt-install --import --name $VM --memory 2048 --vcpus 2 --cpu host --disk $DISK,format=qcow2,bus=virtio --disk $ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --os-variant=centos7.0 --graphics spice --noautoconsole


VM="centos-kvm-k8s-02"
DISK="./centos7-k8s-kvm-imgs/centos7-k8s-base-2"
ISO="./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso"
sudo virt-install --import --name $VM --memory 2048 --vcpus 2 --cpu host --disk $DISK,format=qcow2,bus=virtio --disk $ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --os-variant=centos7.0 --graphics spice --noautoconsole

VM="centos-kvm-k8s-03"
DISK="./centos7-k8s-kvm-imgs/centos7-k8s-base-3"
ISO="./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso"
sudo virt-install --import --name $VM --memory 2048 --vcpus 2 --cpu host --disk $DISK,format=qcow2,bus=virtio --disk $ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --os-variant=centos7.0 --graphics spice --noautoconsole
```

## List guest IP

Getting the guest's IP address from the virtual machines.

*default* here is the network name

```sh
sudo virsh net-list # Get the network name in my case it is "default"
sudo virsh net-dhcp-leases default
```

## Set hostname on the virtual machines

We need to setup the hostname from the vms and set those IP address on their "/etc/hosts" file.
The shell command bellow need gets the IP from the virtual machines and apply an change on the hostnames.

The VM prefix is set to on the variable *VM_Prefix*. In the exaple it is set as "centos-kvm-k8s-0"

```sh
VM_Prefix=centos-kvm-k8s-0
for a in $(sudo virsh net-dhcp-leases default | awk '{print $5}' | grep -o -E '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}');
  do
    ((i=i+1));
    echo ssh root@$a -f hostnamectl set-hostsname $VM_Prefix$i;
done
```

The result will be an execution of the commands as follows:

```text
ssh root@192.168.100.205 -f hostnamectl set-hostsname centos-kvm-k8s-01
ssh root@192.168.100.245 -f hostnamectl set-hostsname centos-kvm-k8s-02
ssh root@192.168.100.176 -f hostnamectl set-hostsname centos-kvm-k8s-03
```

## Adding a user, setting up user password and adding to the docker operating system user group

We have to add an administative user to the virtual machines, and set the user group.
**That will not work remotelly with the /etc/shadow file**

```sh
USER_NAME=born
adduser $USER_NAME
echo "born:$6$PqOMZg/D$o0qQqJs9tBsWrHerTMRsXqyU1sUPqwDZja1rF5/Z4zXp40T/ukrZjCCt0oP1R4u5u0KHsTkFSpzcYq6Ra9SP4/:18368:0:99999:7:::" >> /dev/shadow
echo "born    ALL=(ALL)       ALL" >> /etc/sudoers
usermod -aG docker born
```

## On the master

I have elected the host with the IP address "192.168.100.245" to be the *Master Node*.

Using root user:

```sh
kubeadm init --apiserver-advertise-address 192.168.100.245
```

Verify the output result to execute after on the virtual machines that will be the workers nodes.

```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R  $(id -u):$(id -g) $HOME/.kube/config

# Installing Flannel for network support on K8s.
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --kubeconfig ~/.kube/config
```

## Make the Workers join the cluster

Using the administrative user.

```sh
kubeadm join 192.168.100.245:6443 --token 0zor7p.2z5zs0hbpms1299z --discovery-token-ca-cert-hash sha256:4587252951dd3507a81325eed15926d355527746cfc8d0c7cda1f648ea8e7666
```

## Commands and annotations

## My stuff bellow, I will delete it in the future and add somewhere else

## TODO

Setup the VM's configuration automatically.

1. Set up the K8s Master
2. Set up the log rotation <https://kubernetes.io/docs/concepts/cluster-administration/logging/>
3. Write a app to maintain the log transference based on the IO operations
4. Add user and set the home directory

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

>Values to notice: "disk_size": "10000", it is in mbytes.
It is around 10 gigabytes.

List and Shutdown guest VM KVM command line

```sh
sudo virsh list # it will show the guests running, to list all the guests add --all at the end
sudo virsh shutdown 11 --mode acpi
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
The downloaded location for the Operating System ISO
./packer_cache/4643e65b1345d2b22536e5d371596b98120f4251.iso
```

So, to create the KVM guest we need to add this paths to the command line composition as follows:

> Notice: Plus the VM name.

```sh
# Snapshot the images in case you want to get back to the previous state
sudo virsh snapshot-create-as --domain "centos-kvm-k8s-01" --name centos-kvm-k8s-01_state_0
# Revert to the previous state
sudo virsh snapshot-revert --domain "centos-kvm-k8s-01" --snapshotname centos-kvm-k8s-01_state_0 --running
# To list snapshots
virsh snapshot-list --domain "centos-kvm-k8s-01"
```
