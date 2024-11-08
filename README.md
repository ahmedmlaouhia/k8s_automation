# Kubernetes Cluster Setup

This project contains configuration files and playbooks to set up a multi-node Kubernetes cluster. Follow the instructions below to create an Ansible inventory file with your specific IPs to allow Ansible to connect and configure each instance.

## Prerequisites

- **Ansible** installed on the control machine.
- **SSH access** to each instance, configured with the user `ubuntu`.
- IP addresses of each node in the cluster.

## Inventory Setup

Create an inventory file named `inventory` in the root directory of the project. This file will define the groups and IP addresses of each node in your Kubernetes cluster.

### Example Inventory File

```
[first_controller]
# k8s_control1_eip

[second-controller]
# k8s_control2_eip

[workers]
# k8s_worker1_eip
# k8s_worker2_eip
# k8s_worker3_eip

[instance:children]
first_controller
second-controller
workers

[instance:vars]
ansible_ssh_user=ubuntu
```
