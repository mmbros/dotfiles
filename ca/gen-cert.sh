#!/bin/bash


# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

PROGRAM_NAME=${0##*/}

check_getopt() {
	getopt --test > /dev/null
	if [[ $? -ne 4 ]]; then
	    echo "I’m sorry, `getopt --test` failed in this environment."
	    exit 1
	fi
}

usage() {
	cat <<EOM
Usage: $PROGRAM_NAME [ options ]

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
EOM
}

OPTIONS=t:d:c:n:
LONGOPTIONS=type:,dir:,ca:,common-name:,cn:

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


TYPE=
DIR=
CA_DIR=
COMMON_NAME=

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
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
			usage
            exit 3
            ;;
    esac
done

# handle non-option arguments
# if [[ $# -ne 1 ]]; then
#     echo "$0: A single input file is required."
#     exit 4
# fi

echo "TYPE: $TYPE"
echo "DIR: $DIR"
echo "CA_DIR: $CA_DIR"
echo "COMMON_NAME: $COMMON_NAME"


raise_error()
{
	echo "$PROGRAM_NAME: $1"
	exit 1
}
check_dir ()
{
	[[ -z "$DIR" ]] && raise_error "missing option --dir"
	[[ -e "$DIR" ]] && raise_error "directory already exists --dir=$DIR"
}
check_ca ()
{
	[[ -z "$CA_DIR" ]] && raise_error "missing option --ca"
	[[ ! -d "$CA_DIR" ]] && raise_error "CA directory not found --ca=$CA_DIR"
}
check_common_name ()
{
	[[ -z "$COMMON_NAME" ]] && raise_error "missing option --common_name"
}
check_type ()
{
	[[ -z "$TYPE" ]] && raise_error "missing option -- type"
}
check_confirm ()
{
	echo $1
	read -p "Are you sure? [y/N] " -n 1 -r
	echo    # (optional) move to a new line
	[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
}
check_and_execute()
{
	check_type

	case "$TYPE" in
        ca-root)
			check_dir
			check_confirm "Create a new Root CA at folder \"$DIR\""
			echo Done
            ;;
        ca-intermediate)
			check_dir
			check_ca
			check_confirm "Create a new Intermediate CA at folder \"$DIR\" with parent CA \"$CA_DIR\""
            ;;
		client)
			check_ca
			check_common_name
			check_confirm "Create a new Client Certificate for \"$COMMON_NAME\" with CA \"$CA_DIR\""
			;;
		server)
			check_ca
			check_common_name
			check_confirm "Create a new Server Certificate for \"$COMMON_NAME\" with CA \"$CA_DIR\""
			;;
		*)
			raise_error "invalid value -- type=$TYPE"
			;;
	esac
}


check_and_execute


echo OK
