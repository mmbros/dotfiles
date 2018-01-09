#!/usr/bin/env bash

# OpenSSL Certificate Authority
# https://jamielinux.com/docs/openssl-certificate-authority/index.html

set -e

ROOT_DIR=$HOME/ca/root

declare -A TEMPLATE_PARAMS
TEMPLATE_PARAMS[DIR]=$ROOT_DIR
TEMPLATE_PARAMS[COUNTRY]=IT
TEMPLATE_PARAMS[STATE]=Italy
TEMPLATE_PARAMS[LOCALITY]=Milan
TEMPLATE_PARAMS[ORGANIZATION]="MMbros"
TEMPLATE_PARAMS[UNIT]="MMbros Certificate Authority"
TEMPLATE_PARAMS[COMMON_NAME]="MMbros Root CA"
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


function init_root_dir {
	log_msg "init root dir: $ROOT_DIR"
	mkdir -p $ROOT_DIR
	cd $ROOT_DIR
	mkdir certs crl newcerts private
	chmod 700 private
	touch index.txt
	echo 1000 > serial
}


function create_root_openssl_cnf {
	log_msg "create root openssl_cnf"
	template_to_file "$SCRIPT_DIR/openssl.root.tmpl" "$ROOT_DIR/openssl.cnf"
}


function create_root_key {
	log_msg "create root key"
	cd $ROOT_DIR
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out private/ca.key.pem \
		-pkeyopt rsa_keygen_bits:4096
	chmod 400 private/ca.key.pem
}

function create_root_cert {
	log_msg "create root cert"
	cd $ROOT_DIR
	openssl req \
		-config openssl.cnf \
		-key private/ca.key.pem \
		-new \
		-x509 \
		-days 7300 \
		-sha256 \
		-extensions v3_ca \
		-subj "/CN=${TEMPLATE_PARAMS[COMMON_NAME]}/C=${TEMPLATE_PARAMS[COUNTRY]}/ST=${TEMPLATE_PARAMS[STATE]}/L=${TEMPLATE_PARAMS[LOCALITY]}/O=${TEMPLATE_PARAMS[ORGANIZATION]}/OU=${TEMPLATE_PARAMS[UNIT]}" \
		-out certs/ca.cert.pem
	chmod 444 certs/ca.cert.pem
}

function verify_root_cert {
	log_msg "verify root cert"
	openssl x509 -noout -text -in $ROOT_DIR/certs/ca.cert.pem
}


function main {
  # rm -rf $ROOT_DIR
  init_root_dir
  create_root_openssl_cnf
  create_root_key
  create_root_cert
  verify_root_cert
}

main

