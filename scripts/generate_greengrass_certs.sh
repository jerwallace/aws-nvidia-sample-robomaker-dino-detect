#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" >/dev/null 2>&1 && pwd  )"
CERTS_FOLDER=$BASE_DIR/../robot_ws/src/dinobot/certs

[ ! -d "$CERTS_FOLDER" ] && mkdir -p $CERTS_FOLDER

OUTPUT=$(aws iot create-keys-and-certificate --set-as-active \
    --certificate-pem-outfile "$CERTS_FOLDER/certificate.pem.crt" \
    --private-key-outfile  "$CERTS_FOLDER/private.pem.key" \
    --public-key-outfile  "$CERTS_FOLDER/public.pem.key")

wget -O $CERTS_FOLDER/root.ca.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
