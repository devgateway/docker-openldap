#!/bin/sh -ex
DATA_ROOT=/etc/openldap/config
SLAPDD_DIR=/etc/openldap/slapd.d
: ${PRELOAD_SCHEMAS:=core cosine dyngroup inetorgperson misc nis ppolicy}

if [ "$1" != "slapd" ]; then
  exec "$@"
fi

echo Initializing cn=config database
su -s /usr/sbin/slapadd -- ldap -F "$SLAPDD_DIR" -n 0 <<EOF
dn: cn=config
objectClass: olcGlobal
cn: config

dn: olcDatabase={0}config,cn=config
objectClass: olcDatabaseConfig
olcDatabase: {0}config
olcAccess: to dn.subtree="cn=config"
  by dn=gidNumber=900+uidNumber=900,cn=peercred,cn=external,cn=auth manage
  by * none
EOF

echo Loading bundled schemas
for SCHEMA in $PRELOAD_SCHEMAS; do
  su -s /usr/sbin/slapadd -- ldap -F "$SLAPDD_DIR" -n 0 -l "/etc/openldap/schema/$SCHEMA.ldif"
done

if [ -d "$DATA_ROOT" ]; then
  echo Starting slapd on a local socket
  /usr/libexec/slapd -u ldap -g ldap -F "$SLAPDD_DIR" -h ldapi:/// -d 0 &
  until [ -S "/run/ldapi" ]; do
    echo "Waiting for socket $1"
    sleep 1
  done

  echo Setting up cn=config database
  find "$DATA_ROOT" -maxdepth 1 -type f -name '*.ldif' | sort | while read LDIF; do
    DB_DIR="$(grep -m 1 -i olcDbDirectory: "$LDIF" | cut -d ' ' -f 2)"
    if [ -n "$DB_DIR" ]; then
      mkdir -p -m 0750 "$DB_DIR"
    fi

    if grep -qi changeType "$LDIF"; then
      ldapmodify -H ldapi:/// -f "$LDIF"
    else
      ldapadd    -H ldapi:/// -f "$LDIF"
    fi
  done

  echo Stopping slapd
  kill %1
  wait
fi

# TODO: listen protocols
exec /usr/libexec/slapd -u ldap -g ldap -F "$SLAPDD_DIR" -h "ldapi:/// ldap:///" -d Stats
