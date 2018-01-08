#!/usr/bin/env bash

# OpenSSL Certificate Authority
# https://jamielinux.com/docs/openssl-certificate-authority/index.html

set -e

ROOT_DIR=/home/mau/ca
INTERMEDIATE_DIR=$ROOT_DIR/intermediate
# ---
DEMO_SUFFIX=" (Demo 2018-01-08)"
# ---
COUNTRY=IT
STATE=Italy
LOCALITY=Milan
ORGANIZATION="MMbros Company$DEMO_SUFFIX"
UNIT="MMbros Company Certificate Authority$DEMO_SUFFIX"
EMAIL=
CLIENT_CERT_COMMENT="OpenSSL Generated Client Certificate$DEMO_SUFFIX"
SERVER_CERT_COMMENT="OpenSSL Generated Server Certificate$DEMO_SUFFIX"


TEMPLATE_PARAMS="\
	ROOT_DIR \
 	INTERMEDIATE_DIR \
	COUNTRY \
	STATE \
	LOCALITY \
	ORGANIZATION \
	UNIT \
	EMAIL \
	CLIENT_CERT_COMMENT \
	SERVER_CERT_COMMENT"

SCRIPT_DIR=`pwd`

function template_to_file {
	local TMPL=$1
	local FILE=$2
	shift 2
	local PARAMS=$*
	cp -f $TMPL $FILE
	for name in $PARAMS; do
		sed -i "s@{{$name}}@${!name}@g" $FILE
	done
}


function create_root_openssl_cnf {
  template_to_file "$SCRIPT_DIR/openssl_ca.tmpl" "$ROOT_DIR/openssl.cnf" "$TEMPLATE_PARAMS"
}

function create_intermediate_openssl_cnf {
  template_to_file "$SCRIPT_DIR/openssl_intermediate.tmpl" "$INTERMEDIATE_DIR/openssl.cnf" "$TEMPLATE_PARAMS"
}

function init_root_dir {
  echo "init root dir: $ROOT_DIR"
  mkdir $ROOT_DIR
  cd $ROOT_DIR
  mkdir certs crl newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial
  create_root_openssl_cnf
}


function init_intermediate_dir {
  echo "init intermediate diri: $INTERMEDIATE_DIR"
  mkdir $INTERMEDIATE_DIR
  cd $INTERMEDIATE_DIR
  mkdir certs crl csr newcerts private
  chmod 700 private
  touch index.txt
  echo 1000 > serial
  echo 1000 > clrnumber
  create_intermediate_openssl_cnf
}


function create_root_key {
	echo "create root key"
	cd $ROOT_DIR
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out private/ca.key.pem \
		-pkeyopt rsa_keygen_bits:4096
	chmod 400 private/ca.key.pem
}

function create_root_cert {
	echo "create root cert"
	cd $ROOT_DIR
	openssl req \
		-config openssl.cnf \
		-key private/ca.key.pem \
		-new \
		-x509 \
		-days 7300 \
		-sha256 \
		-extensions v3_ca \
		-out certs/ca.cert.pem
	chmod 444 certs/ca.cert.pem
}

function verify_root_cert {
	echo "verify root cert"
	openssl x509 -noout -text -in $ROOT_DIR/certs/ca.cert.pem
}

function create_intermediate_key {
	echo "create intermediate key"
	cd $INTERMEDIATE_DIR
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out private/intermediate.key.pem \
		-pkeyopt rsa_keygen_bits:4096
	chmod 400 private/intermediate.key.pem
}

function create_intermediate_cert {
	# Use the intermediate key to create a certificate signing request (CSR)
	echo "create intermediate csr"
	cd $INTERMEDIATE_DIR
	openssl req \
		-config openssl.cnf \
		-new \
		-sha256 \
		-key private/intermediate.key.pem \
		-out csr/intermediate.csr.pem
	# To create an intermediate certificate, use the root CA with the
	# v3_intermediate_ca extension to sign the intermediate CSR
	echo "create intermediate cert"
	cd $ROOT_DIR
	openssl ca \
		-config openssl.cnf \
		-extensions v3_intermediate_ca \
		-days 3650 \
		-notext \
		-md sha256 \
		-in intermediate/csr/intermediate.csr.pem \
		-out intermediate/certs/intermediate.cert.pem
	chmod 444 intermediate/certs/intermediate.cert.pem
}

function verify_intermediate_cert {
	echo "verify intermediate cert"
	cd $ROOT_DIR
	openssl x509 -noout -text -in intermediate/certs/intermediate.cert.pem
	openssl verify -CAfile certs/ca.cert.pem intermediate/certs/intermediate.cert.pem
}

function main {
  init_root_dir

  create_root_key
  create_root_cert
  verify_root_cert

  init_intermediate_dir

  create_intermediate_key
  create_intermediate_cert
  verify_intermediate_cert

}

main


