#!/bin/bash

set -e
set -x


# Create a load-balancer
openstack loadbalancer create --wait --name lb1 --vip-subnet-id internal-subnet

# Create a listener
openstack loadbalancer listener create --wait \
  --name listener1 --protocol HTTP --protocol-port 80 lb1

# Create a pool
openstack loadbalancer pool create --wait \
  --name pool1 --lb-algorithm ROUND_ROBIN \
  --listener listener1 --protocol HTTP

# Add a member to the pool
SUBNET_ID=$(openstack subnet show internal-subnet -c id -f value)
vm_id=$(openstack server show lb-member-1 -c id -f value)
ip=$(openstack port list --network internal-network --device-owner compute:nova --device-id "$vm_id" --format json | jq -r '.[]."Fixed IP Addresses"[].ip_address')

openstack loadbalancer member create --wait \
  --subnet $SUBNET_ID \
  --address $ip \
  --name lb-member-1 \
  --protocol 80 pool1

# Add another member to the pool
vm_id=$(openstack server show lb-member-2 -c id -f value)
ip=$(openstack port list --network internal-network --device-owner compute:nova --device-id "$vm_id" --format json | jq -r '.[]."Fixed IP Addresses"[].ip_address')

openstack loadbalancer member create --wait \
  --subnet $SUBNET_ID \
  --address $ip \
  --name lb-member-2 \
  --protocol 80 pool1

# Create a healthmonitor
openstack loadbalancer healthmonitor create --wait \
  --delay 5 --max-retries 4 --timeout 10 \
  --type HTTP \
  --name healthmonitor1 \
  pool1


