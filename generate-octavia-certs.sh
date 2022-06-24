#!/usr/bin/env bash

set -xeu

# This script is adapted from the example steps listed in https://charmhub.io/octavia
CERTIFICATES_DIR="./certs"
PASSPHRASE="foobar"
SUBJECT="/C=US/ST=Somestate/O=Org/CN=www.example.com"
DAYS=36500
KEYSIZE=4096

# Create certificates directory
mkdir -p ${CERTIFICATES_DIR}

# These are referenced by /etc/ssl/openssl.cnf
mkdir -p demoCA/newcerts
touch demoCA/index.txt
touch demoCA/index.txt.attr

# Generate the Octavia CA key and cert. Note that this CA is responsible
# for issuing new certificates to the Amphora LB instances.
openssl genpkey \
  -algorithm RSA -aes256 \
  -pass pass:${PASSPHRASE} \
  -out ${CERTIFICATES_DIR}/issuing_ca_key.pem

# The Octavia CA is its own root CA and is only used for internal comms
# with the Amphora instances. Being it is its own root CA, it also means
# we generate a self-signed certificate.
openssl req -x509 \
  -passin pass:${PASSPHRASE} \
  -new \
  -nodes \
  -key ${CERTIFICATES_DIR}/issuing_ca_key.pem \
  -config /etc/ssl/openssl.cnf \
  -subj "${SUBJECT}" \
  -days ${DAYS} \
  -out ${CERTIFICATES_DIR}/issuing_ca.pem


# Create issuinig key
openssl genpkey \
  -algorithm RSA -aes256 \
  -pass pass:${PASSPHRASE} \
  -out ${CERTIFICATES_DIR}/controller_ca_key.pem

openssl req -x509 \
  -passin pass:${PASSPHRASE} \
  -new -nodes \
  -key ${CERTIFICATES_DIR}/controller_ca_key.pem \
  -config /etc/ssl/openssl.cnf \
  -subj "${SUBJECT}" \
  -days ${DAYS} \
  -out ${CERTIFICATES_DIR}/controller_ca.pem


# Generate Octavia controller's key and csr
openssl req \
  -newkey rsa:${KEYSIZE} \
  -nodes \
  -keyout ${CERTIFICATES_DIR}/controller_key.pem \
  -subj "${SUBJECT}" \
  -out ${CERTIFICATES_DIR}/controller.csr

# Use the Octavia CA to sign Octavia controller's CSR, generating the cert
openssl ca \
  -passin pass:${PASSPHRASE} \
  -config /etc/ssl/openssl.cnf \
  -cert ${CERTIFICATES_DIR}/controller_ca.pem \
  -keyfile ${CERTIFICATES_DIR}/controller_ca_key.pem \
  -create_serial -batch \
  -in ${CERTIFICATES_DIR}/controller.csr \
  -days ${DAYS} \
  -out ${CERTIFICATES_DIR}/controller_cert.pem

# Bundle certificate and key together
cat ${CERTIFICATES_DIR}/controller_cert.pem ${CERTIFICATES_DIR}/controller_key.pem \
  > ${CERTIFICATES_DIR}/controller_cert_bundle.pem
