#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <mds-truststore-password> [base-dir]"
  exit 1
fi

MDS_KEYPAIR_FILE="$2/data/keypair.pem"
MDS_PUBLIC_KEY="$2/data/public.pem"
TRUSTSTORE_FILE="$2/data/truststore.jks"

# Generate keys and certificates used by MDS
if [ \! -e /data/keypair/keypair.pem ]; then
    echo -e "Generate keys and certificates used for MDS"
    openssl genrsa -out /data/keypair.pem 2048; openssl rsa -in ${MDS_KEYPAIR_FILE} -outform PEM -pubout -out ${MDS_PUBLIC_KEY}
    chmod 644 ${MDS_KEYPAIR_FILE} ${MDS_PUBLIC_KEY}
fi

# Import the public keys from Azure EntraID into a keystore used by MDS
# The list Certificate Authorities can be found here:
# https://learn.microsoft.com/en-us/azure/security/fundamentals/azure-CA-details?tabs=root-and-subordinate-cas-list#what-changed

ROOT_CERT_URLS="https://cacerts.digicert.com/DigiCertGlobalRootCA.crt \
  https://cacerts.digicert.com/DigiCertGlobalRootG2.crt \
  https://cacerts.digicert.com/DigiCertGlobalRootG3.crt \
  https://web.entrust.com/root-certificates/entrust_g2_ca.cer \
  https://www.microsoft.com/pkiops/certs/Microsoft%20ECC%20Root%20Certificate%20Authority%202017.crt \
  https://www.microsoft.com/pkiops/certs/Microsoft%20RSA%20Root%20Certificate%20Authority%202017.crt"

i=0
for cert_url in ${ROOT_CERT_URLS}; do
    echo $i: $cert_url
    curl -k -o /tmp/cert.crt $cert_url
    keytool -import -file /tmp/cert.crt -storetype JKS -keystore ${TRUSTSTORE_FILE} -storepass $1 -noprompt -alias CA-$i
    i=$(($i + 1))
done
#keytool -import -alias <alias> -file <idp-certificate> -keystore
#<mds-truststore> -storepass <mds-truststore-password> -noprompt
