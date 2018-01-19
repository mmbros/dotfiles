#!/bin/bash


PARAM1="pippo"
PARAM2="pluto"
PARAM3="paperino"

read -r -d '' ALT << EOM
This is line 1.
This is line 2.
Line 3.
EOM

# template_to_file <src_template> <dst_file> <params...>
template_to_file ()
{
	local TMPL=$1
	local FILE=$2
	shift 2
	local PARAMS=$*

#	cp -f $TMPL $FILE
#	for k in DIR COMMON_NAME COUNTRY STATE LOCALITY ORGANIZATION UNIT \
#		     EMAIL CLIENT_CERT_COMMENT SERVER_CERT_COMMENT; do
#		sed -i "s|{{$k}}|${!k}|g" $FILE
#	done

	echo "TMPL   = $TMPL"
	echo "FILE   = $FILE"
	echo "PARAMS = $PARAMS"

	for k in $PARAMS; do
		echo "$k = ${!k}"
	done
}


template_to_file this.tmpl that.file PARAM1 PARAM2  ALT PARAM3
