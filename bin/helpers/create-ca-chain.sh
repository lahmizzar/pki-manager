#!/bin/bash

#
# Author: Florian Pelgrim
# Email: florian.pelgrim@craneworks.de
# URL: https://github.com/craneworks/pki-manager
# License: MIT (see LICENSE for more informations)
# Copyright 2013
#
# Helper script for creating a ca chain file
# and exporting it into a PKCS#7 der file
#

# Script vars
SCRIPT=`basename $0`

main() {
    CA=$(echo $(basename $CRT) | cut -d "." -f1)
    OUT=$DIR/$CADIR/$CA/$CA$CACHAINEXT$CRTEXT
    PUBOUT=$DIR/$PUBDIR/$CA$CACHAINEXT$PKCS7EXT
    PEMFILE=$DIR/$CADIR/$CA/$CA$CACHAINEXT$PEMEXT

    gen_chain
    gen_pem
    publish
}

gen_chain() {
    cat $CRT $TOP > $OUT
    check $?
}

gen_pem() {
    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' $OUT > $PEMFILE
    check $?
}

publish() {
    openssl crl2pkcs7 -nocrl \
        -certfile $OUT \
        -out $PUBOUT \
        -outform der
    check $?
}

check() {
    if [ $1 -gt 0 ];
    then
        echo "An error occured"
        echo "Return code was $1"
        exit 1
    fi
}

help() {
    echo "
        Usage: $SCRIPT [ARGS] TOP CRT
        
        Helper script for creating and exporting a ca chain file
        
        CRT                 The path to the crt file for our new chain
        TOP                 Path for upper crt/ca-chain file 
        -h, --help          Shows up this help
        "
}

while :
do
    case $1 in
        -h|--help)
            help
            exit 0
            ;;
        *)
            TOP=$1
            CRT=$2
            main
            exit 0
            ;;
    esac
done
