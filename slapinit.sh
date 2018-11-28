#!/bin/sh -e
if [ "$1" != "slapd" ]; then
  exec "$@"
fi

if [ -n "$DEBUG" ]; then
  set -x
fi

DATA_ROOT=/etc/openldap/config
SLAPDD_DIR=/etc/openldap/slapd.d
: ${PRELOAD_SCHEMAS:=core cosine dyngroup inetorgperson misc nis ppolicy}
: ${LISTEN_URIS:=ldap:///}
: ${LOG_LEVEL:=Stats}

echo Bootstrapping the config database
su -s /usr/sbin/slapadd -- ldap -F "$SLAPDD_DIR" -n 0 <<EOF
dn: cn=config
objectClass: olcGlobal
cn: config

dn: olcDatabase={0}config,cn=config
objectClass: olcDatabaseConfig
olcDatabase: {0}config
olcAccess: to dn.subtree="cn=config"
  by dn=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage
  by * none
EOF

echo Loading bundled schemas
for SCHEMA in $PRELOAD_SCHEMAS; do
  su -s /usr/sbin/slapadd -- ldap -F "$SLAPDD_DIR" -n 0 -l "/etc/openldap/schema/$SCHEMA.ldif"
done

if [ -n "$(ls "$DATA_ROOT")" ]; then
  echo Starting slapd on a local socket
  /usr/libexec/slapd -u ldap -g ldap -F "$SLAPDD_DIR" -h ldapi:/// -d 0 &
  for i in $(seq 60); do
    echo Waiting for slapd to become operational
    sleep 1
    ldapsearch -Q -LLL -H ldapi:/// -b cn=config -s base -A dn >/dev/null >/dev/null 2>&1 \
      && break
  done

  echo Setting up the config database
  find "$DATA_ROOT" -maxdepth 1 -type f -name '*.ldif' | sort | while read LDIF; do
    DB_DIR="$(grep -m 1 -i olcDbDirectory: "$LDIF" | cut -d ' ' -f 2)"
    if [ -n "$DB_DIR" ]; then
      mkdir -p -m 0750 "$DB_DIR"
      chown ldap:ldap "$DB_DIR"
    fi

    if grep -qi changeType "$LDIF"; then
      ldapmodify -Q -H ldapi:/// -f "$LDIF"
    else
      ldapadd    -Q -H ldapi:/// -f "$LDIF"
    fi
  done

  echo Stopping slapd
  kill %1
  wait
fi

CA_CERT="$(slapcat -n0 -H 'ldap:///???(olcTLSCACertificateFile=*)' -o ldif-wrap=no \
  | grep -Fi olcTLSCACertificateFile \
  | cut -d ' ' -f 2-)"
if [ -n "$CA_CERT" ]; then
  echo "Making $CA_CERT trusted by clients"
  echo "TLS_CACERT $CA_CERT" >> /etc/openldap/ldap.conf
fi

exec /usr/libexec/slapd -u ldap -g ldap -F "$SLAPDD_DIR" -h "$LISTEN_URIS" -d $LOG_LEVEL
