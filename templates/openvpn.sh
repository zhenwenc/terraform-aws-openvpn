#!/bin/bash

set -e

IMAGE="kylemanna/openvpn"
OPENVPN="docker run -v ${volume}:/etc/openvpn -e EASYRSA_BATCH=true --rm $IMAGE"
OPENVPN_IT="docker run -v ${volume}:/etc/openvpn --rm -it $IMAGE"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_CLEAR='\033[0m'

out() { echo -e "$${COLOR_GREEN}INFO:$${COLOR_CLEAR} $*" >&2; }
err() { echo -e "$${COLOR_RED}ERROR:$${COLOR_CLEAR} $*" 1>&2; exit 1; }
die() { err "EXIT: $1" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

build-server() {
    # Ensure the OpenVPN docker volume exists
    mkdir -p ${volume}

    if [ -d "${volume}/pki" ] ; then
        die ">>> OpenVPN already initialized"
    else
        out ">>> Initializing OpenVPN server"
    fi

    # Setup kylemanna/openvpn as we pre-generated the OpenVPN config
    echo "declare -x OVPN_CN=${domain}" >> ${volume}/ovpn_env.sh
    echo "declare -x OVPN_NAT=0"        >> ${volume}/ovpn_env.sh
    echo "declare -x OVPN_DEFROUTE=0"   >> ${volume}/ovpn_env.sh

    # Generate private key pair for OpenVPN
    # https://github.com/OpenVPN/easy-rsa/blob/master/easyrsa3/easyrsa
    docker run -v ${volume}:/etc/openvpn --rm \
           -e EASYRSA_BATCH=true \
           -e EASYRSA_REQ_COUNTRY="${country}" \
           -e EASYRSA_REQ_PROVINCE="${province}" \
           -e EASYRSA_REQ_CITY="${city}" \
           -e EASYRSA_REQ_ORG="${company}" \
           -e EASYRSA_REQ_EMAIL="${email}" \
           -e EASYRSA_REQ_OU="${section}" \
           -e EASYRSA_REQ_CN="${domain}" \
           -e EASYRSA_KEY_SIZE=1024 \
           "$IMAGE" ovpn_initpki nopass
}

build-client() {
    if [ "$2" = "nopass" ] ; then
        $OPENVPN easyrsa build-client-full "$1" nopass
    else
        $OPENVPN_IT easyrsa build-client-full $*
    fi
}

list-clients() {
    $OPENVPN ovpn_listclients
}

revoke-client() {
    $OPENVPN ovpn_revokeclient "$1" "$${2:-remove}"
}

load-clients() {
    out ">>> Loading OpenVPN clients"

    if [ ! -f "${clients_txt}" ] ; then
        die "Abort! No OpenVPN clients config [${clients_txt}]"
    fi

    if [ ! -d "${volume}/pki" ] ; then
        die "Abort! OpenVPN is not initialized"
    fi

    # An list of existing valid clients
    clients=$($openvpn list-clients | sed -n '1!p' | cut -d',' -f1)

    # Add new clients
    while read -r name ; do
        if [ -z "$name" ] ; then
            continue # skip
        fi

        if grep -qw "$name" <<< "$clients" ; then
            continue # skip
        fi

        out "Adding OpenVPN client: [$name]"
        $openvpn build-client "$name" nopass
    done < "${clients_txt}"

    # Revoke removed clients
    while read -r name ; do
        if [ -z "$name" ] ; then
            continue # skip
        fi

        if grep -qw "$name" "${clients_txt}" ; then
            continue # keep
        fi

        out "Revoking OpenVPN client [$name]"
        $openvpn revoke-client "$name" remove
    done <<< "$clients"
}

get-client() {
    local cn="$1"

    if [ ! -f "${volume}/pki/private/$cn.key" ]; then
        die "Unable to find $cn, please generate the key first"
    fi

    cat "${client_conf}"

    echo "
<key>
$(cat ${volume}/pki/private/$cn.key)
</key>

<cert>
$(openssl x509 -in ${volume}/pki/issued/$cn.crt)
</cert>

<ca>
$(cat ${volume}/pki/ca.crt)
</ca>

<tls-auth>
$(cat ${volume}/pki/ta.key)
</tls-auth>
"
}

#============================================================

if declare -f "$1" > /dev/null ; then
    "$@"
else
    err "[$1] is an invalid command, use:"
    declare -F | sed 's/^declare -f \(.*\)$/  \1/'
    exit 1
fi
