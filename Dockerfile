# Copyright 2018, Development Gateway, see COPYING
FROM alpine:3.8

ARG OPENLDAP_VERSION
ARG OPENLDAP_MIRROR=ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release

RUN set -x; \
  apk add --no-cache libsasl libressl2.7-libssl \
  && addgroup -S -g 900 ldap \
  && adduser -S -G ldap -D -h /var/lib/ldap -u 900 ldap

RUN set -x; \
  apk add --no-cache --virtual .build-deps \
    gcc \
    make \
    groff \
    bash \
    libc-dev \
    cyrus-sasl-dev \
    libressl-dev \
  && wget --proxy on ${OPENLDAP_MIRROR}/openldap-${OPENLDAP_VERSION}.tgz \
  && tar -xf openldap-${OPENLDAP_VERSION}.tgz \
  && cd openldap-${OPENLDAP_VERSION} \
  && export CFLAGS='-O2 -fPIE -s' \
  && ./configure \
    --prefix= \
    --exec-prefix=/usr \
    --mandir=$(pwd) \
    --includedir=$(pwd) \
    --oldincludedir=$(pwd) \
    --enable-dynamic \
    --disable-static \
    --disable-syslog \
    --enable-ipv6 \
    --enable-bdb=no \
    --enable-hdb=no \
    --enable-overlays=mod \
    --with-cyrus-sasl \
    --with-threads \
    --with-tls=openssl \
  && make \
  && make test \
  && make install \
  && cd .. \
  && rm -rf openldap-${OPENLDAP_VERSION}.tgz openldap-${OPENLDAP_VERSION} \
  && apk del .build-deps \
  && rm -f /etc/openldap/slapd.conf \
  && for dir in /etc/openldap/slapd.d /etc/openldap/config /var/lib/ldap; do \
      mkdir -p -m 0750 "$dir" && chown ldap:ldap "$dir"; \
    done

COPY slapinit.sh /slapinit.sh

WORKDIR /var/lib/ldap

ENTRYPOINT ["/slapinit.sh"]
CMD ["slapd"]

VOLUME /var/lib/ldap
VOLUME /etc/openldap/config

EXPOSE 389
EXPOSE 636
