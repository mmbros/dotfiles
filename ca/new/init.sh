#!/bin/bash


	# Create Root CA
	# $0 -t ca-root -d ~/ca/root

	# Create Intermediate CA 1
	# $0 -t ca-intermediate -d ~/ca/ca1 -c ~/ca/root --common-name="Company Inc. CA 1"

	# Create Server certificate
	# $0 -t server -c ~/ca/ca1 -n "*.domain.com" --basename=domain.com

	# Create Client certificate
	# $0 -t client -c ~/ca/ca1 -n user --email=user@domain.com

# set -x
set -e


O="MMbros"
# common directory prefix
d="$HOME/ca-demo"


ORG="--organization=$O"
PW="--password=pass:secpw"

# delete '$d' folder
#rm -rf $d
# Root CA
#./gen-cert -t ca-root -d $d/root "$ORG"  "$PW"
# Intermediate CA
#./gen-cert -t ca-intermediate -d $d/ca1 -c $d/root  --cn="$O CA 1" "$ORG" "$PW"

# OK
# ./gen-cert -t server -c $d/ca1 "$ORG" "$PW" \
# 	--basename='mananno8' --cn='mananno.it' \
# 	--dns='mananno.it' --dns='mananno.dlinkddns.com' --dns='localhost' \
# 	--ip 192.168.1.2 --ip 127.0.0.1

# OK localhost, KO 127.0.0'1
# ./gen-cert -t server -c $d/ca1 "$ORG" "$PW" \
# 	--basename='mananno9' --cn='mananno.it' \
# 	--dns='localhost'


./gen-cert -t client -c $d/ca1 --basename="mananno.user.5" --cn="Mananno User 5" "$ORG" "$PW"

