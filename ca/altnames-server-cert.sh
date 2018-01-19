#!/bin/bash

# https://jamielinux.com/docs/openssl-certificate-authority/ 
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
# https://www.devside.net/wamp-server/generating-and-installing-wildcard-and-multi-domain-ssl-certificates

# set -x

# must be the same CA used in openssl.cnf
CA_DIR="$HOME/ca-AAA/ca2"
BASENAME=mananno.org
# PASSWORD="pass:secpw"
COMMON_NAME="$BASENAME"

# [alt_names]
read -r -d '' ALT_NAMES << EOM
DNS.1 = mananno.it
DNS.2 = mananno.dlinkddns.com
DNS.3 = localhost
IP.1 = 192.168.1.2
IP.2 = 127.0.0.1
EOM
ALT_NAMES="DNS.1 = mananno.it\nDNS.2 = mananno.dlinkddns.com\n"

keyfile="$CA_DIR/private/$BASENAME.key.pem"
csrfile="$CA_DIR/csr/$BASENAME.csr.pem"
certfile="$CA_DIR/certs/$BASENAME.cert.pem"
cafile="$CA_DIR/certs/ca-chain.cert.pem"

tmpl="./altnames.openssl.tmpl"
config="./$BASENAME.openssl.cnf"


ORGANIZATION="MMbros"
UNIT=
COUNTRY=IT
STATE=Italy
LOCALITY=

# internal parameters
PROGRAM=$0
MSG_PREFIX=">>> "

# RET contains (last) function return value (when present)
RET=


# template_to_file <src_template> <dst_file> <params...>
# substitute {{PARAM}} in template with $PARAM
template_to_file ()
{
	local TMPL=$1
	local FILE=$2
	shift 2
	local PARAMS=$*

	# echo "TMPL   = $TMPL"
	# echo "FILE   = $FILE"
	# echo "PARAMS = $PARAMS"

	cp -f $TMPL $FILE
	for k in $PARAMS; do
		echo "$k = ${!k}"
		sed -i "s|{{$k}}|${!k}|g" $FILE
	done
}

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
	# map[EMAIL]=emailAddress;

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


create_key ()
{
	local pass=""

	log_msg "create a key: $keyfile"
	if [[ ! -z "$PASSWORD" ]]; then
		pass="-pass $PASSWORD"
	fi
	#openssl genpkey $pass -algorithm RSA -out "$keyfile" -pkeyopt rsa_keygen_bits:2048
	echo "openssl genpkey -algorithm RSA -out \"$keyfile\" -pkeyopt rsa_keygen_bits:2048"
	openssl genpkey -algorithm RSA -out "$keyfile" -pkeyopt rsa_keygen_bits:2048
	check_error
	chmod 400 "$keyfile"
}

create_csr ()
{
	get_subj
	local subj="$RET"
	local passin=""

	log_msg "Create a certificate signing request: $csrfile"
	if [[ ! -z "$PASSWORD" ]]; then
		passin="-passin $PASSWORD"
	fi
	openssl req $passin \
		-config "$config" \
		-key "$keyfile" \
		-new -sha256 \
		-subj "$subj" \
		-out "$csrfile"
	check_error
}

create_cert ()
{
	local passin=""

	log_msg "Create a certificate: $certfile"
	if [[ ! -z "$PASSWORD" ]]; then
		passin="-passin $PASSWORD"
	fi
	openssl ca $passin \
		-config "$config" \
		-extensions server_cert \
		-days 375 \
		-notext \
		-md sha256 \
		-in "$csrfile" \
		-out "$certfile"
	check_error
	chmod 444 "$certfile"
}


verify_cert ()
{
	log_msg "verify the certificate"

	openssl x509 -noout -text -in "$certfile"
	check_error
	openssl verify -CAfile "$cafile" "$certfile"
	check_error
}


create_openssl_config ()
{
	log_msg "create openssl config file"

	template_to_file $tmpl $config CA_DIR COMMON_NAME ALT_NAMES
	check_error
}


log_msg "Create a new Server Certificate for \"$COMMON_NAME\" with CA \"$CA_DIR\""
# show_distinguished_names "    "
# check_confirm

# rm -f "$csrfile" "$certfile"

create_openssl_config

create_key
create_csr
create_cert
verify_cert
