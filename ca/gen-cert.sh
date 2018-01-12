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

BASENAME=
ORGANIZATION="Company Inc."
UNIT=
COUNTRY=IT
STATE=Italy
LOCALITY=
EMAIL=
CLIENT_CERT_COMMENT="OpenSSL Generated Client Certificate"
SERVER_CERT_COMMENT="OpenSSL Generated Server Certificate"

# internal parameters
PROGRAM=$0
MSG_PREFIX=">>> "

# RET contains (last) function return value (when present)
RET=


usage ()
{
	cat <<EOS
Usage: ${PROGRAM##*/} [ options ]

	Create a certificate of given type.

Main options:

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

	-b, --basename <name>
		Basename of the created files. Example: <basename>.key.pem

Other options:

	--organization <text>   Organization (default "$ORGANIZATION")
	--unit <text>           Unit (default "$UNIT")
	--country <text>        Country (default "$COUNTRY")
	--state <text>          State (default "$STATE")
	--locality <text>       Locality (default "$LOCALITY")
	--email <text>          Email (default "$EMAIL")

Examples:

	# Create Root CA
	$0 -t ca-root -d ~/ca/root

	# Create Intermediate CA 1
	$0 -t ca-intermediate -d ~/ca/ca1 -c ~/ca/root --common-name="Company Inc. CA 1"

	# Create Server certificate
	$0 -t server -c ~/ca/ca1 -n "*.domain.com" --basename=domain.com

	# Create Client certificate
	$0 -t client -c ~/ca/ca1 -n user --email=user@domain.com

EOS
}

# getopt params
OPTIONS=ht:d:c:n:b:
LONGOPTIONS=help,type:,dir:,ca:,common-name:,cn:,organization:,country:,state:,locality:unit:,email:,basename:

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
        -b|--basename)
            BASENAME="$2"
            shift 2
            ;;
        --organization)
            ORGANIZATION="$2"
            shift 2
            ;;
        --country)
            COUNTRY="$2"
            shift 2
            ;;
        --state)
            STATE="$2"
            shift 2
            ;;
        --locality)
            LOCALITY="$2"
            shift 2
            ;;
        --unit)
            UNIT="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
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
	read -r -p "Are you sure? [y/n] "
	case "$REPLY" in
	    [yY][eE][sS]|[yY])
	        ;;
	    *)
			log_msg "Abort"
			exit 1
	        ;;
	esac
}

check_error ()
{
	if [[ $? != 0 ]]; then
		log_msg "Abort"
		exit 1
	fi
}


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

get_subj ()
{

	local subj=""
	local val=""
	declare -A map
	map[COMMON_NAME]=CN;
	map[ORGANIZATION]=O;
	map[UNIT]=OU;
	map[COUNTRY]=C;
	map[STATE]=ST;
	map[LOCALITY]=L;
	map[EMAIL]=emailAddress;

	# subj "/CN=$COMMON_NAME/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$UNIT"

	for k in ${!map[@]}; do
		val="${!k}"
		if [[ ! -z "$val" ]]; then
			subj="$subj/${map[$k]}=$val"
		fi
	done
	RET=$subj

	#echo "get_subj -> $subj"
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

check_opt_basename ()
{
	case "$TYPE" in
		ca-root|ca-intermediate)
			BASENAME=ca
			;;
		*)
			BASENAME=${BASENAME:-$COMMON_NAME}
    esac
	echo "BASENAME -> $BASENAME"
}

check_opt_type ()
{
	[[ -z "$TYPE" ]] && raise_error_missing_option "--type"
}

check_opt_organization ()
{
	[[ -z "$ORGANIZATION" ]] && raise_error_missing_option "--organization"
}

check_opt_country ()
{
	[[ -z "$COUNTRY" ]] && raise_error_missing_option "--country"
}

check_opt_state ()
{
	[[ -z "$STATE" ]] && raise_error_missing_option "--state"
}

init_root_dir ()
{
	log_msg "init Root CA dir: $DIR"
	for d in certs crl newcerts private; do
		mkdir -p "$DIR/$d"
	done
	chmod 700 "$DIR/private"
	touch "$DIR/index.txt"
	echo 1000 > "$DIR/serial"
}


create_root_openssl_cnf ()
{
	log_msg "create root openssl.cnf"
	template_to_file "openssl.root.tmpl" "$DIR/openssl.cnf"
}


create_root_key ()
{
	local keyfile="$DIR/private/ca.key.pem"

	log_msg "create root key: $keyfile"
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out "$keyfile" \
		-pkeyopt rsa_keygen_bits:4096
	check_error
	chmod 400 "$keyfile"
}

create_root_cert ()
{
	local config="$DIR/openssl.cnf"
	local keyfile="$DIR/private/ca.key.pem"
	local certfile="$DIR/certs/ca.cert.pem"
	get_subj
	local subj="$RET"

	log_msg "create root cert: $certfile"
	openssl req \
		-config "$config" \
		-key "$keyfile" \
		-new \
		-x509 \
		-days 7300 \
		-sha256 \
		-extensions v3_ca \
		-subj "$subj" \
		-out "$certfile"
	check_error
	chmod 444 "$certfile"
}

verify_root_cert ()
{
	log_msg "verify root cert"
	openssl x509 -noout -text -in "$DIR/certs/ca.cert.pem"
	check_error
}

create_intermediate_openssl_cnf ()
{
	log_msg "create openssl.cnf"
	template_to_file "openssl.intermediate.tmpl" "$DIR/openssl.cnf"
}

init_intermediate_dir ()
{
	log_msg "init intermediate dir: $DIR"
	for d in certs crl csr newcerts private; do
		mkdir -p "$DIR/$d"
	done
	chmod 700 "$DIR/private"
	touch "$DIR/index.txt"
	echo 1000 > "$DIR/serial"
	echo 1000 > "$DIR/clrnumber"
}


create_intermediate_key ()
{
	local keyfile="$DIR/private/ca.key.pem"

	log_msg "create intermediate key: $keyfile"
	openssl genpkey \
		-algorithm RSA \
		-aes-256-cbc \
		-out "$keyfile" \
		-pkeyopt rsa_keygen_bits:4096
	check_error
	chmod 400 "$keyfile"
}

create_intermediate_csr ()
{
	# Use the intermediate key to create a certificate signing request (CSR)
	local config="$DIR/openssl.cnf"
	local keyfile="$DIR/private/ca.key.pem"
	local csrfile="$DIR/csr/ca.csr.pem"
	get_subj
	local subj="$RET"

	log_msg "create intermediate csr: $csrfile"
	openssl req \
		-config "$config" \
		-new \
		-sha256 \
		-key "$keyfile" \
		-out "$csrfile"
		#-subj "$subj" \
	check_error
}

create_intermediate_cert ()
{
	# To create an intermediate certificate, use the root CA with the
	# v3_intermediate_ca extension to sign the intermediate CSR
	local config="$CA_DIR/openssl.cnf"
	local csrfile="$DIR/csr/ca.csr.pem"
	local certfile="$DIR/certs/ca.cert.pem"

	log_msg "create intermediate cert: $certfile"
	openssl ca \
		-config "$config" \
		-extensions v3_intermediate_ca \
		-days 3650 \
		-notext \
		-md sha256 \
		-in "$csrfile" \
		-out "$certfile"
	check_error
	chmod 444 "$certfile"
}

verify_intermediate_cert ()
{
	local cafile="$CA_DIR/certs/ca.cert.pem"
	local certfile="$DIR/certs/ca.cert.pem"

	openssl x509 -noout -text -in "$certfile"
	check_error
	openssl verify -CAfile "$cafile" "$certfile"
	check_error
}

create_cert_chain_file ()
{
	local cafile="$CA_DIR/certs/ca.cert.pem"
	local certfile="$DIR/certs/ca.cert.pem"
	local chainfile="$DIR/certs/ca-chain.cert.pem"

	log_msg "create cert chain file: $chainfile"
	cat "$certfile" \
		"$cafile" \
		> "$chainfile"
	check_error
	chmod 444 "$chainfile"
}

create_key ()
{
	local keyfile="$CA_DIR/private/$BASENAME.key.pem"

	log_msg "create a key: $keyfile"
	openssl genpkey -algorithm RSA -out "$keyfile" -pkeyopt rsa_keygen_bits:2048
	check_error
	chmod 400 "$keyfile"
}

create_csr ()
{
	local config="$CA_DIR/openssl.cnf"
	local keyfile="$CA_DIR/private/$BASENAME.key.pem"
	local csrfile="$CA_DIR/csr/$BASENAME.csr.pem"
	get_subj
	local subj="$RET"

	log_msg "Create a certificate signing request: $csrfile"
	openssl req -config "$config" \
		-key "$keyfile" \
		-new -sha256 \
		-subj "$subj" \
		-out "$csrfile"
	check_error
}

create_cert ()
{
	# arg1 = [server | usr]
	local cert_type="$1_cert"
	local config="$CA_DIR/openssl.cnf"
	local csrfile="$CA_DIR/csr/$BASENAME.csr.pem"
	local certfile="$CA_DIR/certs/$BASENAME.cert.pem"

	log_msg "Create a certificate: $certfile"
	openssl ca -config "$config" \
		-extensions "$cert_type" \
		-days 375 \
		-notext \
		-md sha256 \
		-in "$csrfile" \
		-out "$certfile"
	check_error
	chmod 444 "$certfile"
}


create_pkcs ()
{
	# Convert Client Key to PKCS
	# so that it may be installed in most browsers
	local keyfile="$CA_DIR/private/$BASENAME.key.pem"
	local crtfile="$CA_DIR/certs/$BASENAME.cert.pem"
	local p12file="$CA_DIR/certs/$BASENAME.p12.pem"

	log_msg "create a pkcs certificate: $p12file"
	openssl pkcs12 -export -clcerts -in "$crtfile" -inkey "$keyfile" -out "$p12file"
	check_error
	chmod 444 "$p12file"
}

verify_cert ()
{
	log_msg "verify the certificate"
	local crtfile="$CA_DIR/certs/$BASENAME.cert.pem"
	local cafile="$CA_DIR/certs/ca-chain.cert.pem"

	openssl x509 -noout -text -in "$crtfile"
	check_error
	openssl verify -CAfile "$cafile" "$crtfile"
	check_error
}

show_distinguished_names ()
{
	log_msg "$1Common Name (CN) : $COMMON_NAME"
	log_msg "$1Organization (O) : $ORGANIZATION"
	log_msg "$1Unit (OU)        : $UNIT"
	log_msg "$1Country (C)      : $COUNTRY"
	log_msg "$1State (ST)       : $STATE"
	log_msg "$1Locality (L)     : $LOCALITY"
	log_msg "$1Email Address    : $EMAIL"
}

check_and_execute()
{
	# print_params
	check_opt_type
	check_opt_basename

	case "$TYPE" in

        ca-root)
			check_opt_dir
			check_opt_organization
			#check_opt_country
			#check_opt_state
			check_opt_common_name "$ORGANIZATION Root CA"
			log_msg "Create a new Root CA for \"$COMMON_NAME\" at folder \"$DIR\""
			show_distinguished_names "    "
			check_confirm
			init_root_dir
			create_root_openssl_cnf
			create_root_key
			create_root_cert
			verify_root_cert
            ;;

        ca-intermediate)
			check_opt_dir
			check_opt_organization
			#check_opt_country
			#check_opt_state
			check_opt_common_name "$ORGANIZATION Intermediate CA ${DIR##*/}"
			check_opt_ca
			log_msg "Create a new Intermediate CA for \"$COMMON_NAME\" at folder \"$DIR\" with parent CA \"$CA_DIR\""
			show_distinguished_names "    "
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
			show_distinguished_names "    "
			check_confirm
			create_key
			create_csr
			create_cert usr
			verify_cert
			create_pkcs
			;;

		server)
			check_opt_ca
			check_opt_common_name
			log_msg "Create a new Server Certificate for \"$COMMON_NAME\" with CA \"$CA_DIR\""
			show_distinguished_names "    "
			check_confirm
			create_key
			create_csr
			create_cert server
			verify_cert
			;;

		*)
			raise_error "invalid value -- type=$TYPE"
			;;
	esac
}


check_and_execute

