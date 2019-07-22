CERTS_FOLDER=../robot_ws/src/dinobot/certs
if ![ -d "$CERTS_FOLDER" ]; then
    mkdir $CERTS_FOLDER
fi
OUTPUT=$(aws iot create-keys-and-certificate --set-as-active \
    --certificate-pem-outfile $CERTS_FOLDER/certificate.pem.crt \
    --private-key-outfile  $CERTS_FOLDER/private.pem.key
    --public-key-outfile  $CERTS_FOLDER/public.pem.key)
wget -O $CERTS_FOLDER/root.ca.pem wget -O $CERTS_FOLDER/root.ca.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem