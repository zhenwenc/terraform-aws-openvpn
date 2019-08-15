#!/bin/bash
#
# This script is designed to be ran inside the OpenVPN docker
# container, be careful do not override the environment variables
# defined in 'kylemanna/openvpn' image.

set -e

# IMAGE="kylemanna/openvpn"
# OPENVPN="docker run -v ${volume}:/etc/openvpn -e EASYRSA_BATCH=true --rm $IMAGE"
# OPENVPN_IT="docker run -v ${volume}:/etc/openvpn --rm -it $IMAGE"

CONFIG_DIR="/opt/openvpn"
SERVER_CONF="$CONFIG_DIR/openvpn.conf"
CLIENT_CONF="$CONFIG_DIR/client.ovpn"
CLIENTS_FILE="$CONFIG_DIR/clients.txt"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_CLEAR='\033[0m'

out() { echo -e "$${COLOR_GREEN}INFO:$${COLOR_CLEAR} $*" >&2; }
err() { echo -e "$${COLOR_RED}ERROR:$${COLOR_CLEAR} $*" 1>&2; exit 1; }
die() { err "EXIT: $1" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

start-server() {
    if [ ! -d "$EASYRSA_PKI" ] ; then
        build-server
    fi

    load-clients

    out ">>> Launching OpenVPN server..."
    ovpn_run --config $SERVER_CONF
}

build-server() {
    if [ -d "$EASYRSA_PKI" ] ; then
        die ">>> OpenVPN already initialized"
    else
        out ">>> Initializing OpenVPN server"
    fi

    # Setup kylemanna/openvpn as we pre-generated the OpenVPN config
    echo "declare -x OVPN_CN=${domain}" >> $OPENVPN/ovpn_env.sh
    echo "declare -x OVPN_NAT=0"        >> $OPENVPN/ovpn_env.sh
    echo "declare -x OVPN_DEFROUTE=0"   >> $OPENVPN/ovpn_env.sh

    # Generate private key pair for OpenVPN
    # https://github.com/OpenVPN/easy-rsa/blob/master/easyrsa3/easyrsa
    ovpn_initpki nopass
}

build-client() {
    if [ "$2" = "nopass" ] ; then
        easyrsa build-client-full "$1" nopass
    else
        die "VPN client with password is not yet supported!"
    fi
}

list-clients() {
    ovpn_listclients
}

revoke-client() {
    ovpn_revokeclient "$1" "$${2:-remove}"
}

load-clients() {
    out ">>> Loading OpenVPN clients"

    if [ ! -f "$CLIENTS_FILE" ] ; then
        die "Abort! No OpenVPN clients config [$CLIENTS_FILE]"
    fi

    if [ ! -d "$EASYRSA_PKI" ] ; then
        die "Abort! OpenVPN is not initialized"
    fi

    # An list of existing valid clients
    clients=$(list-clients | sed -n '1!p' | cut -d',' -f1)

    # Add new clients
    while read -r name ; do
        if [ -z "$name" ] ; then
            continue # skip
        fi

        if grep -qw "$name" <<< "$clients" ; then
            continue # skip
        fi

        out "Adding OpenVPN client: [$name]"
        build-client "$name" nopass
    done < "$CLIENTS_FILE"

    # Revoke removed clients
    while read -r name ; do
        if [ -z "$name" ] ; then
            continue # skip
        fi

        if grep -qw "$name" "$CLIENTS_FILE" ; then
            continue # keep
        fi

        out "Revoking OpenVPN client [$name]"
        revoke-client "$name" remove
    done <<< "$clients"
}

get-client() {
    local cn="$1"

    if [ ! -f "$EASYRSA_PKI/private/$cn.key" ]; then
        die "Unable to find $cn, please generate the key first"
    fi

    cat "$CLIENT_CONF"

    echo "
<key>
$(cat $EASYRSA_PKI/private/$cn.key)
</key>

<cert>
$(openssl x509 -in $EASYRSA_PKI/issued/$cn.crt)
</cert>

<ca>
$(cat $EASYRSA_PKI/ca.crt)
</ca>

<tls-auth>
$(cat $EASYRSA_PKI/ta.key)
</tls-auth>
"
}

#============================================================

export EASYRSA_BATCH=true
export EASYRSA_REQ_COUNTRY="${country}"
export EASYRSA_REQ_PROVINCE="${province}"
export EASYRSA_REQ_CITY="${city}"
export EASYRSA_REQ_ORG="${company}"
export EASYRSA_REQ_EMAIL="${email}"
export EASYRSA_REQ_OU="${section}"
export EASYRSA_REQ_CN="${domain}"
export EASYRSA_KEY_SIZE=1024

if declare -f "$1" > /dev/null ; then
    "$@"
else
    err "[$1] is an invalid command, use:"
    declare -F | sed 's/^declare -f \(.*\)$/  \1/'
    exit 1
fi
