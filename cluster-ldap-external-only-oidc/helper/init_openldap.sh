#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ]; then
  echo "Usage: $0 <ldap-host> <ldap-domain> <ldap-base-dn> <ldap-admin-password> <ldap-config-password>"
  exit 1
fi
LDAP_HOST=${1}
LDAP_DOMAIN=${2}
LDAP_BASE_DN="${3}"
LDAP_ADMIN_PASS="${4}"
LDAP_CONFIG_PASS="${5}"
LDAP_ADD="ldapadd -H ldap://${LDAP_HOST} -x -w ${LDAP_ADMIN_PASS} -D cn=admin,${LDAP_BASE_DN} -a -c -v -v"

#echo "Enabling 'memberOf' overlay in LDAP"
#ldapadd -H ldap://${LDAP_HOST} -x -w ${LDAP_CONFIG_PASS} -D cn=admin,cn=config -a -c -v -v<<EOF
#dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
#objectClass: olcOverlayConfig
#objectClass: olcMemberOf
#olcOverlay: memberof
#olcMemberOfRefint: TRUE
#EOF

# Configure access controls to allow read access to all entries
ldapadd -H ldap://${LDAP_HOST} -x -w ${LDAP_CONFIG_PASS} -D cn=admin,cn=config -a -c -v -v<<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: to * by * read
EOF

echo "Creating ou=groups in LDAP"
${LDAP_ADD} <<EOF
dn: ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: organizationalUnit
ou: groups
EOF

echo "Creating ou=users in LDAP"
${LDAP_ADD} <<EOF
dn: ou=users,${LDAP_BASE_DN}
objectClass: top
objectClass: organizationalUnit
ou: users
EOF

echo "Initializing users in LDAP"

LDAP_USERS="readonly mds client client2 client3"

USER_UID=1000

for LDAP_USER in ${LDAP_USERS}; do
# Set password to the username. Do not use in production!
LDAP_PASS=$(slappasswd -h "{CRYPT}" -n -s "${LDAP_USER}")

#${LDAP_ADD} <<EOF
#dn: cn=${LDAP_USER},ou=users,${LDAP_BASE_DN}
#objectClass: inetOrgPerson
#objectClass: organizationalPerson
#objectClass: person
#objectClass: top
#cn: ${LDAP_USER}
#sn: ${LDAP_USER}
#userPassword: ${LDAP_PASS}
#EOF
${LDAP_ADD} <<EOF
dn: cn=${LDAP_USER},ou=users,${LDAP_BASE_DN}
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
cn: ${LDAP_USER}
uid: ${LDAP_USER}
sn: ${LDAP_USER}
uidNumber: ${USER_UID}
gidNumber: 5000
homeDirectory: /home/${LDAP_USER}
loginShell: /bin/bash
userPassword: ${LDAP_PASS}
ou: users
EOF
USER_UID=$((USER_UID + 1))
done

${LDAP_ADD} <<EOF
dn: cn=kafkaadmin,ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: posixGroup
objectClass: groupOfNames
cn: kafkaadmin
gidNumber: 5001
member: CN=client3,ou=users,${LDAP_BASE_DN}
EOF

#${LDAP_ADD} <<EOF
#dn: cn=kafka,ou=groups,${LDAP_BASE_DN}
#objectClass: top
#objectClass: groupOfNames
#cn: kafka
#member: CN=client,ou=users,${LDAP_BASE_DN}
#member: CN=client2,ou=users,${LDAP_BASE_DN}
#member: CN=client3,ou=users,${LDAP_BASE_DN}
#EOF
${LDAP_ADD} <<EOF
dn: cn=kafka,ou=groups,${LDAP_BASE_DN}
objectClass: top
objectClass: posixGroup
objectClass: groupOfNames
cn: kafka
gidNumber: 5000
member: CN=client,ou=users,${LDAP_BASE_DN}
member: CN=client2,ou=users,${LDAP_BASE_DN}
member: CN=client3,ou=users,${LDAP_BASE_DN}
EOF

exit 0

