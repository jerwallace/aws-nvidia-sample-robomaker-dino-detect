CERTS_FOLDER=../robot_ws/src/dinobot/certs
if ![ -d "$CERTS_FOLDER" ]; then
    mkdir $CERTS_FOLDER
fi
aws iot create-keys-and-certificate --set-as-active \
    --certificate-pem-outfile $CERTS_FOLDER/certificate.pem.crt \
    --private-key-outfile  ../robot_ws/src/dinobot/certs/private.pem.key
    --public-key-outfile  ../robot_ws/src/dinobot/certs/public.pem.key
wget -O 