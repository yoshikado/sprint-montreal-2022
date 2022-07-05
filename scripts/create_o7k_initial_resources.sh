#!/bin/bash

set -e
set -x

source openrc

# Create a flavor
openstack flavor create --vcpu 1 --ram 1024 --disk 5 m1.small

# Create a SSH keypair
ssh-keygen -N '' -f ~/.ssh/id_rsa.demo -C demo-key@$HOSTNAME
openstack keypair create --public-key ~/.ssh/id_rsa.demo.pub mykey

# Create an internal network
openstack network create internal-network
openstack subnet create \
    --network internal-network \
    --subnet-range 192.168.11.0/24 \
    internal-subnet

# Create a security groups
openstack security group create ssh
openstack security group rule create --proto tcp --dst-port 22 ssh
openstack security group create icmp
openstack security group rule create --proto icmp icmp
openstack security group create http
openstack security group rule create --proto tcp --dst-port 80 http
openstack security group create https
openstack security group rule create --proto tcp --dst-port 443 https


# Create an external network
openstack network create --external \
  --provider-network-type flat \
  --provider-physical-network physnet1 \
  ext-net
openstack subnet create --no-dhcp \
    --network ext-net \
    --subnet-range 10.0.1.0/24 \
    --allocation-pool start=10.0.1.10,end=10.0.1.200 \
    ext-subnet

# Create a router between internal and external networks
openstack router create sample-router
openstack router add subnet sample-router internal-subnet
openstack router set --external-gateway ext-net sample-router

