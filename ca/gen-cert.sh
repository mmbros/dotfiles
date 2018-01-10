#!/bin/bash

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I’m sorry, `getopt --test` failed in this environment."
    exit 1
fi

# set -x

# options parameters
TYPE=
DIR=
CA_DIR=
COMMON_NAME=

COUNTRY="IT"
STATE="Italy"
LOCALITY="Milan"
ORGANIZATION="Company Inc."
UNIT="Company Inc. Certificate Authority"
EMAIL=
CLIENT_CERT_COMMENT="OpenSSL Generated Client Certificate"
SERVER_CERT_COMMENT="OpenSSL Generated Server Certificate"

# internal parameters
PROGRAM=$0
SCRIPT_DIR=`pwd`
MSG_PREFIX=">>> "

usage ()
{
	cat <<EOS
Usage: ${PROGRAM##*/} [ options ]

	Create a certificate of given type.

	-t, --type <cert-type>
		Type of certificate (mandatory).
		cert-type = (ca-root | ca-intermediate | server | client)

	-d, --dir <path>
		Directory of the new CA certificate.
		Mandatory for ca-root and ca-intermediate cert-type. Ignored otherwise. 

	-c, --ca-dir <path>
		Directory of the existing CA certificate.
		Ignored for ca-root cert-type. Mandatory otherwise.

	-n, --cn, --common-name <name>
		Common Name (CN) of the certificate.
EOS
}

# getopt params
OPTIONS=t:d:c:n:h
LONGOPTIONS=type:,dir:,ca:,common-name:,cn:,help

# -temporarily store output to be able to check for errors
# -e.g. use “--options” parameter by name to activate quoting/enhanced mode
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -h|--help)
			usage
            exit 0
            ;;
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -d|--dir)
            DIR="$2"
            shift 2
            ;;
        -c|--ca)
            CA_DIR="$2"
            shift 2
            ;;
        -n|--common-name|--cn)
            COMMON_NAME="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# handle non-option arguments
if [[ $# -ne 0 ]]; then
    # echo "$0: A single input file is required."
	echo "$0: Invalid argument(s) -- $@."
    exit 1
fi

raise_error ()
{
	echo "$PROGRAM: $1"
	exit 1
}

raise_error_missing_option ()
{
	raise_error "missing option $1. Try -h for help."
}

print_params ()
{
	echo "TYPE: $TYPE"
	echo "DIR: $DIR"
	echo "CA_DIR: $CA_DIR"
	echo "COMMON_NAME: $COMMON_NAME"
}

log_msg ()
{
	echo "${MSG_PREFIX}$1"
}

check_confirm ()
{
	read -p "${MSG_PREFIX}Are you sure? [y/N] " -n 1 -r
	echo
	[[ ! $REPLY =~ ^[Yy]$ ]] && log_msg "Abort" && exit 1
}


# template_to_file ()
# {
# 	local TMPL=$1
# 	local FILE=$2
# 	cp -f $TMPL $FILE
# 	for k in "${!TEMPLATE_PARAMS[@]}"; do
# 		sed -i "s|{{$k}}|${TEMPLATE_PARAMS[$k]}|g" $FILE
# 	done
# }

template_to_file ()
{
	local TMPL=$1
	local FILE=$2
	cp -f $TMPL $FILE
	for k in DIR COMMON_NAME COUNTRY STATE LOCALITY ORGANIZATION UNIT \
		     EMAIL CLIENT_CERT_COMMENT SERVER_CERT_COMMENT; do
		sed -i "s|{{$k}}|${!k}|g" $FILE
	done
}

check_opt_dir ()
{
	[[ -z "$DIR" ]] && raise_error_missing_option "--dir"
	[[ -e "$DIR" ]] && raise_error "directory already exists --dir=$DIR"
}

check_opt_ca ()
{
	[[ -z "$CA_DIR" ]] && raise_error_missing_option "--ca"
	[[ ! -d "$CA_DIR" ]] && raise_error "CA directory not found --ca=$CA_DIR"
}

check_opt_common_name ()
{
	# if COMMON_NAME is empty, it's updated with the passed argument (if present)
	COMMON_NAME=${COMMON_NAME:-"$1"}
	[[ -z "$COMMON_NAME" ]] && raise_error_missing_option "--common_name"
}

check_opt_type ()
{
	[[ -z "$TYPE" ]] && raise_error_missing_option "--type"
}


function init_root_dir {
	log_msg "init Root CA dir: $DIR"
	mkdir -p $DIR
	cd $DIR
	mkdir certs crl newcerts private
	chmod 700 private
	touch index.txt
	echo 1000 > serial
}


function create_root_openssl_cnf {
	log_msg "create root openssl.cnf"
	template_to_file "$SCRIPT_DIR/openssl.root.tmpl" "$DIR/openssl.cnf"
}


function create_root_key {
	log_msg "create root key"
	local keyfile="$DIR/private/ca.key.pem"
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out "$keyfile" \
		-pkeyopt rsa_keygen_bits:4096
	chmod 400 "$keyfile"
}

function create_root_cert {
	log_msg "create root cert"
	local config="$DIR/openssl.cnf"
	local keyfile="$DIR/private/ca.key.pem"
	local certfile="$DIR/certs/ca.cert.pem"
	openssl req \
		-config "$config" \
		-key "$keyfile" \
		-new \
		-x509 \
		-days 7300 \
		-sha256 \
		-extensions v3_ca \
		-subj "/CN=$COMMON_NAME/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$UNIT" \
		-out "$certfile"
	chmod 444 "$certfile"
}

function verify_root_cert {
	log_msg "verify root cert"
	openssl x509 -noout -text -in "$DIR/certs/ca.cert.pem"
}

create_intermediate_openssl_cnf ()
{
	log_msg "create openssl.cnf"
	template_to_file "$SCRIPT_DIR/openssl.intermediate.tmpl" "$DIR/openssl.cnf"
}

init_intermediate_dir ()
{
	log_msg "init intermediate dir: $DIR"
	mkdir $DIR
	cd $DIR
	mkdir certs crl csr newcerts private
	chmod 700 private
	touch index.txt
	echo 1000 > serial
	echo 1000 > clrnumber
}


create_intermediate_key ()
{
	log_msg "create intermediate key"
	local keyfile="$DIR/private/ca.key.pem"
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out "$keyfile" \
		-pkeyopt rsa_keygen_bits:4096
	chmod 400 "$keyfile"
}

create_intermediate_csr ()
{
	# Use the intermediate key to create a certificate signing request (CSR)
	log_msg "create intermediate csr"
	local config="$DIR/openssl.cnf"
	local keyfile="$DIR/private/ca.key.pem"
	local csrfile="$DIR/csr/ca.csr.pem"
	openssl req \
		-config "$config" \
		-new \
		-sha256 \
		-subj "/CN=$COMMON_NAME/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$UNIT" \
		-key "$keyfile" \
		-out "$csrfile"
}

create_intermediate_cert ()
{
	# To create an intermediate certificate, use the root CA with the
	# v3_intermediate_ca extension to sign the intermediate CSR
	log_msg "create intermediate cert"
	local config="$CA_DIR/openssl.cnf"
	local csrfile="$DIR/csr/ca.csr.pem"
	local certfile="$DIR/certs/ca.cert.pem"
	openssl ca \
		-config "$config" \
		-extensions v3_intermediate_ca \
		-days 3650 \
		-notext \
		-md sha256 \
		-in "$csrfile" \
		-out "$certfile"
	chmod 444 "$certfile"
}

verify_intermediate_cert ()
{
	log_msg "verify intermediate cert"
	local cafile="$CA_DIR/certs/ca.cert.pem"
	local certfile="$DIR/certs/ca.cert.pem"
	openssl x509 -noout -text -in "$certfile"
	openssl verify -CAfile "$cafile" "$certfile"
}

create_cert_chain_file ()
{
	log_msg "create cert chain file"
	local cafile="$CA_DIR/certs/ca.cert.pem"
	local certfile="$DIR/certs/ca.cert.pem"
	local chainfile="$DIR/certs/ca-chain.cert.pem"
	cat "$certfile" \
		"$cafile" \
		> "$chainfile"
	chmod 444 "$chainfile"
}


check_and_execute()
{
	print_params
	check_opt_type

	case "$TYPE" in

        ca-root)
			check_opt_dir
			check_opt_common_name "$ORGANIZATION Root CA"
			log_msg "Create a new Root CA at folder \"$DIR\""
			log_msg "    Common Name (CN): $COMMON_NAME"
			check_confirm
			init_root_dir
			create_root_openssl_cnf
			create_root_key
			create_root_cert
			verify_root_cert
            ;;

        ca-intermediate)
			check_opt_dir
			check_opt_common_name "$ORGANIZATION Intermediate CA ${DIR##*/}"
			check_opt_ca
			log_msg "Create a new Intermediate CA at folder \"$DIR\" with parent CA \"$CA_DIR\""
			log_msg "    Common Name (CN): $COMMON_NAME"
			check_confirm
			init_intermediate_dir
			create_intermediate_openssl_cnf
			create_intermediate_key
			create_intermediate_csr
			create_intermediate_cert
			verify_intermediate_cert
			create_cert_chain_file
            ;;

		client)
			check_opt_ca
			check_opt_common_name
			log_msg "Create a new Client Certificate for \"$COMMON_NAME\" with CA \"$CA_DIR\""
			log_msg "    Common Name (CN): $COMMON_NAME"
			check_confirm
			;;

		server)
			check_opt_ca
			check_opt_common_name
			log_msg "Create a new Server Certificate for \"$COMMON_NAME\" with CA \"$CA_DIR\""
			log_msg "    Common Name (CN): $COMMON_NAME"
			check_confirm
			;;

		*)
			raise_error "invalid value -- type=$TYPE"
			;;
	esac
}


check_and_execute

