FROM alpine:3.8

ARG OPENLDAP_VERSION=2.4.46
ARG OPENLDAP_MIRROR=ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release

RUN apk add cyrus-sasl openssl

RUN set -ex \
  && wget -nv ${OPENLDAP_MIRROR}/openldap-${OPENLDAP_VERSION}.tgz \
  && tar -xf openldap-${OPENLDAP_VERSION}.tgz \
  && cd openldap-${OPENLDAP_VERSION} \
  && apk add --no-cache --virtual .build-deps \
    gcc \
    make \
    groff \
    libc-dev \
    cyrus-sasl-dev \
    openssl-dev \
  && ./configure \
    --prefix= \
    --exec-prefix=/usr \
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
  && apk del .build-deps \
  && rm -rf openldap-${OPENLDAP_VERSION}.tgz openldap-${OPENLDAP_VERSION}
