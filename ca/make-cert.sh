#!/usr/bin/env bash

set -e

COMMON_NAME=$1
IPATH="$HOME/ca/${2:-intermediate1}"

if [ "$COMMON_NAME" == "" ]; then
	echo "Usage: $0 common_name [ca]"
	echo "  Example: $0 www.example.com"
	echo "  Example: $0 username@example.com intermediate2"
	exit 1
fi

echo "Making a certificate for \"$COMMON_NAME\""
echo "with \"$IPATH\" certification autority."

# default
COUNTRY=IT

# Variables
KEYPATH="$IPATH/private/$COMMON_NAME.key.pem"
CRTPATH="$IPATH/certs/$COMMON_NAME.cert.pem"
P12PATH="$IPATH/certs/$COMMON_NAME.p12.pem"
CSRPATH="$IPATH/csr/$COMMON_NAME.csr.pem"

function log_msg {
	echo ">>> $1"
}

function create_key {
	log_msg "Create a key"
	openssl genpkey -algorithm RSA -out "$KEYPATH" -pkeyopt rsa_keygen_bits:2048
	chmod 400 "$KEYPATH"
}

function create_csr {
	log_msg "Create a certificate signing request"
	openssl req -config "$IPATH/openssl.cnf" \
		-key "$KEYPATH" \
		-new -sha256 \
		-subj "/CN=$COMMON_NAME/C=$COUNTRY" \
		-out "$CSRPATH"
}

function create_server_cert {
	log_msg "Create a server certificate"
	openssl ca -config "$IPATH/openssl.cnf" \
		-extensions server_cert \
		-days 375 \
		-notext \
		-md sha256 \
		-in "$CSRPATH" \
		-out "$CRTPATH"
	chmod 444 "$CRTPATH"
}

function create_client_cert {
	log_msg "Create a server certificate"
	openssl ca -config "$IPATH/openssl.cnf" \
		-extensions client_cert \
		-days 375 \
		-notext \
		-md sha256 \
		-in "$CSRPATH" \
		-out "$CRTPATH"
	chmod 444 "$CRTPATH"
}

function create_pkcs {
	# Convert Client Key to PKCS
	# so that it may be installed in most browsers
	openssl pkcs12 -export -clcerts -in "$CRTPATH" -inkey "$KEYPATH" -out "$P12PATH"
	chmod 444 "$P12PATH"
}

function verify_cert {
	log_msg "Verify the certificate"
	openssl x509 -noout -text -in "$CRTPATH"
	openssl verify -CAfile "$IPATH/certs/ca-chain.cert.pem" "$CRTPATH"
}


