#!/usr/bin/env bash

# OpenSSL Certificate Authority
# https://jamielinux.com/docs/openssl-certificate-authority/index.html

set -e

INTERMEDIATE_SUFFIX=${1:-1}

INTERMEDIATE_DIR="$HOME/ca/intermediate$INTERMEDIATE_SUFFIX"
ROOT_DIR="$HOME/ca/root"

declare -A TEMPLATE_PARAMS
TEMPLATE_PARAMS[DIR]=$INTERMEDIATE_DIR
TEMPLATE_PARAMS[COUNTRY]=IT
TEMPLATE_PARAMS[STATE]=Italy
TEMPLATE_PARAMS[LOCALITY]=Milan
TEMPLATE_PARAMS[ORGANIZATION]="MMbros"
TEMPLATE_PARAMS[UNIT]="MMbros Certificate Authority"
TEMPLATE_PARAMS[COMMON_NAME]="MMbros CA $INTERMEDIATE_SUFFIX"
TEMPLATE_PARAMS[EMAIL]=""
TEMPLATE_PARAMS[CLIENT_CERT_COMMENT]="OpenSSL Generated Client Certificate"
TEMPLATE_PARAMS[SERVER_CERT_COMMENT]="OpenSSL Generated Server Certificate"


SCRIPT_DIR=`pwd`

function log_msg {
	echo ">>> $1"
}

function template_to_file {
	local TMPL=$1
	local FILE=$2
	cp -f $TMPL $FILE
	for k in "${!TEMPLATE_PARAMS[@]}"; do
		sed -i "s|{{$k}}|${TEMPLATE_PARAMS[$k]}|g" $FILE
	done
}


function create_intermediate_openssl_cnf {
	log_msg "create openssl.cnf"
	template_to_file "$SCRIPT_DIR/openssl.intermediate.tmpl" "$INTERMEDIATE_DIR/openssl.cnf"
}


function init_intermediate_dir {
	log_msg "init intermediate dir: $INTERMEDIATE_DIR"
	mkdir $INTERMEDIATE_DIR
	cd $INTERMEDIATE_DIR
	mkdir certs crl csr newcerts private
	chmod 700 private
	touch index.txt
	echo 1000 > serial
	echo 1000 > clrnumber
}


function create_intermediate_key {
	log_msg "create intermediate key"
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out $INTERMEDIATE_DIR/private/ca.key.pem \
		-pkeyopt rsa_keygen_bits:4096
	chmod 400 $INTERMEDIATE_DIR/private/ca.key.pem
}

function create_intermediate_csr {
	# Use the intermediate key to create a certificate signing request (CSR)
	log_msg "create intermediate csr"
	openssl req \
		-config $INTERMEDIATE_DIR/openssl.cnf \
		-new \
		-sha256 \
		-subj "/CN=${TEMPLATE_PARAMS[COMMON_NAME]}/C=${TEMPLATE_PARAMS[COUNTRY]}/ST=${TEMPLATE_PARAMS[STATE]}/L=${TEMPLATE_PARAMS[LOCALITY]}/O=${TEMPLATE_PARAMS[ORGANIZATION]}/OU=${TEMPLATE_PARAMS[UNIT]}" \
		-key $INTERMEDIATE_DIR/private/ca.key.pem \
		-out $INTERMEDIATE_DIR/csr/ca.csr.pem
}

function create_intermediate_cert {
	# To create an intermediate certificate, use the root CA with the
	# v3_intermediate_ca extension to sign the intermediate CSR
	log_msg "create intermediate cert"
	openssl ca \
		-config $ROOT_DIR/openssl.cnf \
		-extensions v3_intermediate_ca \
		-days 3650 \
		-notext \
		-md sha256 \
		-in $INTERMEDIATE_DIR/csr/ca.csr.pem \
		-out $INTERMEDIATE_DIR/certs/ca.cert.pem
	chmod 444 $INTERMEDIATE_DIR/certs/ca.cert.pem
}

function verify_intermediate_cert {
	log_msg "verify intermediate cert"
	openssl x509 -noout -text -in $INTERMEDIATE_DIR/certs/ca.cert.pem
	openssl verify -CAfile $ROOT_DIR/certs/ca.cert.pem $INTERMEDIATE_DIR/certs/ca.cert.pem
}

function create_cert_chain_file {
	log_msg "create cert chain file"
	cat "$INTERMEDIATE_DIR/certs/ca.cert.pem" \
		"$ROOT_DIR/certs/ca.cert.pem" \
		> "$INTERMEDIATE_DIR/certs/ca-chain.cert.pem"
	chmod 444 "$INTERMEDIATE_DIR/certs/ca-chain.cert.pem"
}


function main {
	init_intermediate_dir
	create_intermediate_openssl_cnf
	create_intermediate_key
	create_intermediate_csr
	create_intermediate_cert
	verify_intermediate_cert
	create_cert_chain_file
}

main

