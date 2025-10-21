#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ]; then
  echo "Usage: $0 <ldap-host> <ldap-domain> <ldap-base-dn> <ldap-admin-password>"
  exit 1
fi
LDAP_HOST=${1}
LDAP_DOMAIN=${2}
LDAP_BASE_DN="${3}"
LDAP_ADDMIN_PASS="${4}"
LDAP_ADD="ldapadd -H ldap://${LDAP_HOST} -x -w ${LDAP_ADDMIN_PASS} -D cn=admin,${LDAP_BASE_DN} -v -v"

echo "Creating ou=groups in LDAP"
${LDAP_ADD} <<EOF
dn: ou=groups,${LDAP_BASE_DN}
ou: groups
objectClass: top
objectClass: organizationalUnit
EOF

echo "Creating ou=users in LDAP"
${LDAP_ADD} <<EOF
dn: ou=users,${LDAP_BASE_DN}
ou: users
objectClass: top
objectClass: organizationalUnit
EOF

${LDAP_ADD} <<EOF
dn: cn=kafka,ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: group
cn: kafka
member: CN=client,ou=users,${LDAP_BASE_DN}
member: CN=client2,ou=users,${LDAP_BASE_DN}
member: CN=client3,ou=users,${LDAP_BASE_DN}
EOF

${LDAP_ADD} <<EOF
dn: cn=kafka,ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: group
cn: kafkaadmin
member: CN=client3,ou=users,${LDAP_BASE_DN}
EOF

echo "Initializing users in LDAP"

LDAP_USERS="readonly mds client client2 client3"

for LDAP_USER in ${LDAP_USERS}; do
# Set password to the username. Do not use in production!
LDAP_PASS=$(slappasswd -n -s "${LDAP_USER}")

 ${LDAP_ADD} <<EOF
dn: cn=${LDAP_USER},ou=users,${LDAP_BASE_DN}
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: ${LDAP_USER}
sAMAccountName: ${LDAP_USER}
userPrincipalName: ${LDAP_USER}@${LDAP_DOMAIN}
mail: ${LDAP_USER}@${LDAP_HOST}@${LDAP_DOMAIN}
userPassword: ${LDAP_PASS}
EOF
done


exit 0
