#!/bin/bash

set -e
set -x

source openrc

# Create two test instances
openstack server create \
  --image auto-sync/ubuntu-focal-20.04-amd64-server-20220615-disk1.img \
  --flavor m1.small \
  --network internal-network \
  --security-group ssh \
  --key-name mykey \
  --min 2 \
  --max 2 \
  --wait \
  test

# Set a name to the ports for readability later in OVN
openstack port set --name test-1-port \
  $(openstack port list --server test-1 -f value -c ID)
openstack port set --name test-2-port \
  $(openstack port list --server test-2 -f value -c ID)

