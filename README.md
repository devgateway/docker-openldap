# OpenLDAP image for Docker

This image is built on Alpine Linux with LibreSSL TLS, SASL, and IPv6 support. The only available
backend in LMDB, as recommended by the upstream.

## Ports

TCP ports 389 and 636 are exposed, but by default `slapd` only listens on 389 without TLS.

## User

Slapd starts as root, then drops privileges to user `ldap`, uid 900.

## Volumes

### `/var/lib/ldap`

Data root, must be writable by user `ldap`. For multiple databases, use subdirectories. These
subdirectories will be automatically created by the startup script.

### `/etc/openldap/config`

Configuration files for the server. The startup script will search for `*.ldif` files recursively,
and load them in alphabetical order. Files that contain `changeType` pseudo-attribute, will be
loaded using `ldapmodify`, otherwise `ldapadd` will be used.

See `tests/*/config` for examples of files in this volume.

You should store other files here, such as TLS keys and certs, or Diffie-Hellman params.

It is recommended to mount this volume read-only. LDIF files will be read by `root`, but keys and
certs must be readable by user `ldap`.

## Environment Variables

### `PRELOAD_SCHEMAS`

Base names of bundled schemas (without `.ldif` extension) from `/etc/openldap/schemas` to load
before startup. For custom schemas, add them as LDIF files into your `/etc/openldap/config` volume.
Make sure to order them correctly to avoid dependency problems.

Default: `core cosine dyngroup inetorgperson misc nis ppolicy`

### `LOG_LEVEL`

Debug level recognized by slapd, appears as container stderr output.

See `man slapd(8)` regarding the `-d` option.

Default: `Stats`

### `LISTEN_URIS`

Space-delimited list of URI that slapd should listen on.

See `man slapd(8)` regarding the `-h` option.

Default: `ldap:///`

### `DEBUG`

If defined, enables shell `x` option, print commands in the startup script.

## Copyright

Copyright 2018, Development Gateway

See COPYING for details.
