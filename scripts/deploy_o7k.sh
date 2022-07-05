#!/bin/bash

set -e
set -x

juju deploy ./openstack-bundle-aws.yaml

juju-wait -w --exclude neutron-api-plugin-ovn \
    --exclude ovn-chassis \
    --exclude ovn-central \
    --exclude octavia \
    --exclude octavia-ovn-chassis \
    --exclude barbican-vault \
    --exclude vault


juju ssh vault/0 '
  VAULT_ADDR=http://localhost:8200 vault operator init \
    -key-shares=1 -key-threshold=1 -format=json
  ' | tee vault-keys.json

key="$(cat vault-keys.json | jq -r .unseal_keys_b64[])"
token="$(cat vault-keys.json | jq -r .root_token)"


juju ssh vault/0 "
  VAULT_ADDR='http://localhost:8200' vault operator unseal $key
"

juju run-action --wait vault/0 authorize-charm token="$token"


juju-wait -w --exclude octavia

juju run-action --wait glance-simplestreams-sync/leader sync-images
juju run-action --wait octavia/leader configure-resources

juju run --unit octavia/0 -- hooks/config-changed

