#!/bin/bash

set -e
set -x

# Create a client instance
openstack server create \
  --image auto-sync/ubuntu-focal-20.04-amd64-server-20220711-disk1.img \
  --flavor m1.small \
  --network internal-network \
  --security-group ssh \
  --security-group icmp \
  --key-name mykey \
  --wait \
  client

# Create two test backend instances
openstack server create \
  --image auto-sync/ubuntu-focal-20.04-amd64-server-20220711-disk1.img \
  --flavor m1.small \
  --network internal-network \
  --security-group ssh \
  --security-group icmp \
  --security-group http \
  --security-group https \
  --key-name mykey \
  --user-data ./cloud-config \
  --min 2 \
  --max 2 \
  --wait \
  lb-member

