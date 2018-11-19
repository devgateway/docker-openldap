#!/bin/sh -ex
DATA_ROOT=/etc/openldap/config

echo Initializing cn=config database
slapadd -n 0 -l config.ldif

echo Loading bundled schemas
for LDIF in /etc/openldap/schema/*.ldif; do
  slapadd -n 0 -l "$LDIF"
done

if [ -d "$DATA_ROOT" ]; then
  echo Starting slapd on a local socket
  /usr/libexec/slapd -h ldapi:/// -d 0 &
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
  wait %1
fi

# TODO: listen protocols
exec /usr/libexec/slapd -h "ldapi:/// ldap:///" -d Stats
