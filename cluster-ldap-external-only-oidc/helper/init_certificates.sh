#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <mds-truststore-password> [base-dir]"
  exit 1
fi

apply_shell_expansion() {
    while read; do
        eval echo "$REPLY"
    done < $1
}

MDS_KEYPAIR_FILE="/keys/keypair.pem"
MDS_PUBLIC_KEY="/keys/public.pem"
TRUSTSTORE_FILE="/keys/truststore.jks"

# Generate keys and certificates used by MDS
if [ \! -e ${MDS_KEYPAIR_FILE} ]; then
    echo -e "Generate keys and certificates used for MDS"
    openssl genrsa -out ${MDS_KEYPAIR_FILE} 2048; openssl rsa -in ${MDS_KEYPAIR_FILE} -outform PEM -pubout -out ${MDS_PUBLIC_KEY}
    chmod 644 ${MDS_KEYPAIR_FILE} ${MDS_PUBLIC_KEY}
fi

# Import the public keys from Azure EntraID into a keystore used by MDS
# The list Certificate Authorities can be found here:
# https://learn.microsoft.com/en-us/azure/security/fundamentals/azure-CA-details?tabs=root-and-subordinate-cas-list#what-changed

if [ \! -e /tmp/cert.crt ]; then
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
fi
#keytool -import -alias <alias> -file <idp-certificate> -keystore
#<mds-truststore> -storepass <mds-truststore-password> -noprompt

create_kafka_oauthbearer_config () {
cat > $1 <<EOF
    sasl.mechanism=OAUTHBEARER
    security.protocol=SASL_PLAINTEXT
    group.id=console-consumer-group
    sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler
    sasl.oauthbearer.token.endpoint.url=$2
    sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required \\
      clientId="$3" \\
      clientSecret="$4" \\
      scope="$5";
EOF
}

echo "Creating client files"
create_kafka_oauthbearer_config /mount/superuser.properties "$IDP_TOKEN_ENDPOINT" "$SUPERUSER_CLIENT_ID" "$SUPERUSER_CLIENT_SECRET" "$AZURE_OAUTH_SCOPE"
create_kafka_oauthbearer_config /mount/client.properties "$IDP_TOKEN_ENDPOINT" "$CLIENT_APP_ID" "$CLIENT_APP_SECRET" "$AZURE_OAUTH_SCOPE"
exit 0
