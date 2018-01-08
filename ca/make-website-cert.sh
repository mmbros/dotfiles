#!/usr/bin/env bash

set -e

IPATH="/home/mau/ca/intermediate";

DOMAIN=$1

if [ "$DOMAIN" == "" ]; then
	echo "Usage: $0 domain";
	echo "  Example: $0 www.example.com";
	exit 1;
fi


# Create a key
KEYPATH="$IPATH/private/$DOMAIN.key.pem";
echo "KEYPATH=$KEYPATH"

# openssl genrsa -out "$KEYPATH" 2048;
openssl genpkey -algorithm RSA -out "$KEYPATH" -pkeyopt rsa_keygen_bits:2048;
chmod 400 "$KEYPATH";

# Create a certificate signing request
CSRPATH="$IPATH/csr/$DOMAIN.csr.pem";
openssl req -config "$IPATH/openssl.cnf" \
	      -key "$KEYPATH" \
		        -new -sha256 \
				      -subj "/CN=$DOMAIN/C=DE" \
					        -out "$CSRPATH";

# Create a certificate
CRTPATH="$IPATH/certs/$DOMAIN.cert.pem";
openssl ca -config "$IPATH/openssl.cnf" \
	      -extensions server_cert -days 375 -notext -md sha256 \
		        -in "$CSRPATH" \
				      -out "$CRTPATH";
chmod 444 "$CRTPATH";

# Verify the certificate
openssl x509 -noout -text -in "$CRTPATH";

openssl verify -CAfile "$IPATH/certs/ca-chain.cert.pem" "$CRTPATH"
