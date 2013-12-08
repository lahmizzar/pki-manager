#!/bin/bash

#
# Author: Florian Pelgrim
# Email: florian.pelgrim@craneworks.de
# URL: https://github.com/craneworks/pki-manager
# License: MIT (see LICENSE for more informations)
# Copyright 2013
#
# Wrapper script to go every step through for building a CA
#

# Script vars
SCRIPT=`basename $0`
PASSWORD="NULL"


source ./etc/vars

main() {
    if [[ ! $CA || ! $i -eq 1 ]] || [[ $INTERMEDIATECA && ! $SIGNCA ]] || [[ $SIGNINGCA && ! $SIGNCA ]];
    then
        help
        exit 1
    fi

    if [[ $ENCRYPTION && ! $SIGNINCA ]];
    then
        echo "Warning: You're trying to build an important CA without password protection!"
        echo "This option is only supported for signing-cas"
        help
        exit 1
    fi

    if [ $ROOTCA ];
    then
        CFG="$CFGDIR/$CA$CFGEXT"
        CA="$CA$ROOTCAEXT"
        CANAME="$ROOTCAEXT"
        SCRIPTARG="--root-ca"
        TOPCFG=$CFG
    elif [ $INTERMEDIATECA ];
    then
        CFG="$CFGDIR/$CA/$CA$CFGEXT"
        CA="$CA$INTERMEDIATEEXT"
        TOPCA="$SIGNCA$ROOTCAEXT"
        TOPCFG="$CFGDIR/$SIGNCA$CFGEXT"
        CANAME="$INTERMEDIATEEXT"
        SCRIPTARG="--intermediate-ca"
    elif [ $SIGNINGCA ];
    then
        CFG="$CFGDIR/$SIGNCA/$CA$CFGEXT"
        TOPCFG="$CFGDIR/$SIGNCA/$SIGNCA$CFGEXT"
        TOPCA="$SIGNCA$INTERMEDIATEEXT"
        SCRIPTARG="--signing-ca"

        if [ $SIGNCA == $CA ];
        then
            echo "Conflict! Signing CA has the same name as the unit"
            exit 1
        fi
    fi

    export CANAME=$(echo $(basename $CFG) | \
                        awk -F "." -v name="$CANAME" '{print $1name}')
    if [[ $SIGNCA && ! $ROOTCA ]];
    then
        CRT=$DIR/$CADIR/$CA/$CA$CRTEXT
        if [ $INTERMEDIATECA ];
        then
            export ROOTCANAME=$TOPCA
            export INTERMEDIATECANAME=$CANAME
            TOP=$DIR/$CADIR/$TOPCA/$TOPCA$CRTEXT
        else
            export INTERMEDIATECANAME=$TOPCA
            CACHAIN=$DIR/$CADIR/$TOPCA/$TOPCA$CACHAINEXT$PEMEXT
            TOP=$CACHAIN
        fi
    else
        export ROOTCANAME=$CANAME
        CRT=$DIR/$CADIR/$CA/$CANAME$CRTEXT
    fi

    if [[ ! $ENCRYPTION && ! $PARANOID ]];
    then
        ask_password
        while [[ "$PASSWORD" != "$PASSWORD2" ]] || [[ "$PASSWORD" = "" ]] || [[ `echo $PASSWORD | wc -m` -lt $PASSWORDSTRENGHT ]];
        do
            echo ""
            if [ "$PASSWORD" = "" ];
            then
                echo "Password empty. Try again."
            elif [ "$PASSWORD" != "$PASSWORD2" ];
            then
                echo "Password missmatch. Try again."
            else
                echo "Password too weak. Must have at least $PASSWORDSTRENGHT chars. Try again."
            fi
            ask_password
        done

        TEMP=$(tempfile)
        echo $PASSWORD > $TEMP
        PASSWD="--password-file $TEMP"
    fi

    if [ ! $ROOTCA ];
    then
        echo ""
        read -s -p "Enter your password for $TOPCA: " SIGNPASSWORD

        TEMP=$(tempfile)
        echo $SIGNPASSWORD > $TEMP
        SIGNPASSWD="--password-file $TEMP"
    else
        SIGNPASSWD=$PASSWD
    fi


    init
    request
    sign
    init_crl
    if [ ! $ROOTCA ];
    then
        create_ca_chain
    fi

    shred $TEMP
}

init() {
    bash $DEBUG ./bin/helpers/init-ca.sh $CA
    check $?
}

request() {
    bash $DEBUG ./bin/helpers/request-certificate.sh $PASSWD $ENCRYPTION --ca --cfg $CFG $CA
    check $?
}

sign() {
    bash $DEBUG ./bin/helpers/signing-certificate.sh $SIGNPASSWD $SCRIPTARG --cfg $TOPCFG $CA
    check $?
}

init_crl() {
    bash $DEBUG ./bin/helpers/create-crl.sh $PASSWD $CFG $CA
    check $?
}

create_ca_chain() {
    bash $DEBUG ./bin/helpers/create-ca-chain.sh $TOP $CRT
    check $?
}

ask_password() {
    echo ""
    read -s -p "Enter a password for $CA: " PASSWORD
    echo ""
    read -s -p "Reenter your password: " PASSWORD2
}

check() {
    if [ $1 -gt 0 ];
    then
        #echo "An error occured"
        #echo "Return code was $1"
        exit 1
    fi
}

help() {
    echo "
        Usage: $SCRIPT [ARGS] CA
        
        Wrapper script to go every step through for building a CA

        CA                  Name of the new CA
        -d, --debug         Enable bash debug mode
        -h, --help          Shows up this help
        --intermediate-ca   Build an intermediate ca
        --no-password       Don't protect the private key with a challenge (only for signing-cas)
        --paranoid          Don't store the password in a temp file
        --root-ca           Build a root ca
        --signing-ca        Build a signing ca
        --sign-with         CA used to sign the new CA
        "
}

i=0
while :
do
    case $1 in
        -d|--debug)
            set -x
            DEBUG="-x"
            shift 1
            ;;
        -h|--help)
            help
            exit 0
            ;;
        --intermediate-ca)
            INTERMEDIATECA="true"
            i=$(($i + 1))
            shift
            ;;
        --no-password)
            ENCRYPTION="--no-password"
            shift
            ;;
        --paranoid)
            PARANOID="true"
            shift
            ;;
        --root-ca)
            ROOTCA="true"
            i=$(($i + 1))
            shift
            ;;
        --signing-ca)
            SIGNINGCA="true"
            i=$(($i + 1))
            shift
            ;;
        --sign-with)
            SIGNCA=$2
            shift 2
            ;;
        --sign-with=*)
            SIGNCA=${1#*=}
            shift
            ;;
        *)
            CA=$1
            main
            exit 0
            ;;
    esac
done
