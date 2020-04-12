**Contents**

<!-- TOC -->

- [Deploy Kubernetes cluster using Packer and Kickstart - Centos 7.x hands-on lab step-by-step](#deploy-kubernetes-cluster-using-packer-and-kickstart---centos-7.x-hands-on-lab-step-by-step)
  - [Abstract and learning objectives](#abstract-and-learning-objectives)
  - [Overview](#overview)
  - [Solution architecture](#solution-architecture)
  - [Requirements](#requirements)
  - [Main task 1: Installing Packer](#provision-a-three-nodes-kubernet-cluster)
    - [Task 1: Setting up your local environment to run Packer](#setting-up-your-local-environment-to-run-packer)
    - [Task 2: Browsing to the web application](#task-2-browsing-to-the-web-application)
    - [Task 3: Create a Dockerfile](#task-3-create-a-dockerfile)
  - [Main task 2: Deploy the solution to Azure Kubernetes Service](#exercise-2-deploy-the-solution-to-azure-kubernetes-service)
    - [Task 1: Tunnel into the Azure Kubernetes Service cluster](#task-1-tunnel-into-the-azure-kubernetes-service-cluster)
    - [Task 2: Deploy a service using the Kubernetes management dashboard](#task-2-deploy-a-service-using-the-kubernetes-management-dashboard)
    - [Task 3: Deploy a service using kubectl](#task-3-deploy-a-service-using-kubectl)
    - [Task 4: Deploy a service using a Helm chart](#task-4-deploy-a-service-using-a-helm-chart)
    - [Task 5: Initialize database with a Kubernetes Job](#task-5-initialize-database-with-a-kubernetes-job)
    - [Task 6: Test the application in a browser](#task-6-test-the-application-in-a-browser)
    - [Task 7: Configure Continuous Delivery to the Kubernetes Cluster](#task-7-configure-continuous-delivery-to-the-kubernetes-cluster)
    - [Task 8: Review Azure Monitor for Containers](#task-8-review-azure-monitor-for-containers)
  - [Exercise 3: Scale the application and test HA](#exercise-3-scale-the-application-and-test-ha)
    - [Task 1: Increase service instances from the Kubernetes dashboard](#task-1-increase-service-instances-from-the-kubernetes-dashboard)
    - [Task 2: Increase service instances beyond available resources](#task-2-increase-service-instances-beyond-available-resources)
    - [Task 3: Restart containers and test HA](#task-3-restart-containers-and-test-ha)
  - [Exercise 4: Working with services and routing application traffic](#exercise-4-working-with-services-and-routing-application-traffic)
    - [Task 1: Scale a service without port constraints](#task-1-scale-a-service-without-port-constraints)
    - [Task 2: Update an external service to support dynamic discovery with a load balancer](#task-2-update-an-external-service-to-support-dynamic-discovery-with-a-load-balancer)
    - [Task 3: Adjust CPU constraints to improve scale](#task-3-adjust-cpu-constraints-to-improve-scale)
    - [Task 4: Perform a rolling update](#task-4-perform-a-rolling-update)
    - [Task 5: Configure Kubernetes Ingress](#task-5-configure-kubernetes-ingress)
  - [After the hands-on lab](#after-the-hands-on-lab)

<!-- /TOC -->

# Deploy Kubernetes cluster using Packer and Kickstart - Centos hands-on

## Abstract and learning objectives

This hands-on lab is designed to guide you through the process of building and deploying a Kubernetes Cluster using Packer and KickStart. In addition to learning how to work with remote log administration, first commands for Kubernetes administration. (service scale-out, and high-availability, monitoring and trancing, will be a next project).

## Overview

Launch a Kubernetes cluster with three nodes, using CentOS. The logs have to be defined to rotate based on IO operations, and moved to a remote server. The condition to be moved need to respect low IO operations. In other words, if the IO operations are lower than 30% the rotate logs should be moved to a remote server. 

## Solution architecture

## Requirements

## Commands and annotations

Push to master

When git completes, ssh-agent terminates, and the key is forgotten.

```sh
ssh-agent bash -c 'ssh-add ~/.ssh/packer-centos7-kvm-k8s; git push git@github.com:dev-sre-21/packer-centos-kvm-k8s.git'
```

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

1. References: 
* Push to master -  <https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent>