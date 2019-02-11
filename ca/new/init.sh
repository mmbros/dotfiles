#!/bin/bash


	# Create Root CA
	# $0 -t ca-root -d ~/ca/root

	# Create Intermediate CA 1
	# $0 -t ca-intermediate -d ~/ca/ca1 -c ~/ca/root --common-name="Company Inc. CA 1"

	# Create Server certificate
	# $0 -t server -c ~/ca/ca1 -n "*.domain.com" --basename=domain.com

	# Create Client certificate
	# $0 -t client -c ~/ca/ca1 -n user --email=user@domain.com

set -x
set -e


k=Demo

O="MMbros"
DIR_PREFIX="$HOME/ca-"
d=$DIR_PREFIX$k
ORG="--organization=$O $k"
PW=--password=pass:secpw

rm -rf $d
./gen-cert -t ca-root -d $d/root "$ORG"  $PW
./gen-cert -t ca-intermediate -d $d/ca1 -c $d/root  --cn="$O $k CA 1" "$ORG" $PW
./gen-cert -t server -c $d/ca1  --cn="Mananno Web Server" "$ORG" $PW --dns=mananno.it --dns='mananno dlinkddns.com' --dns=localhost --ip 127.0.0.1 --ip 192.168.1.2
# ./gen-cert -t server -c $d/ca1  --cn="$O $k Server CA 1" "$ORG" $PW --dns=mananno.it --dns=mananno.dlinkddns.com --dns=localhost
# ./gen-cert -t server -c $d/ca1  --cn="$O $k Server CA 1" "$ORG" $PW --ip 127.0.0.1 --ip=192.168.1.2

# ./gen-cert -t server -c $d/ca1  --cn="$O $k Server CA 1" "$ORG" $PW
# ./gen-cert -t client -c $d/ca1  --cn="$O $k User CA 1" "$ORG" $PW


# ./gen-cert -t ca-intermediate -d $d/ca2 -c $d/root  --cn="$O $k Intermediate CA 2" "$ORG" $PW
# ./gen-cert -t client -c $d/ca2  --cn="$O $k User CA 2" "$ORG" $PW

# ./gen-cert -t server -c $d/ca1  --cn="localhost" "$ORG" $PW
# ./gen-cert -t client -c $d/ca1  --cn="$O $k User CA 1" "$ORG" $PW
