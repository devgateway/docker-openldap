FROM alpine:3.8

ARG OPENLDAP_VERSION=2.4.46
ARG OPENLDAP_MIRROR=ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release

RUN apk add cyrus-sasl openssl

RUN set -x; \
  apk add --no-cache --virtual .build-deps \
    gcc \
    make \
    groff \
    bash \
    libc-dev \
    cyrus-sasl-dev \
    openssl-dev \
  && wget --proxy on ${OPENLDAP_MIRROR}/openldap-${OPENLDAP_VERSION}.tgz \
  && tar -xf openldap-${OPENLDAP_VERSION}.tgz \
  && cd openldap-${OPENLDAP_VERSION} \
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
  && cd .. \
  && rm -rf openldap-${OPENLDAP_VERSION}.tgz openldap-${OPENLDAP_VERSION} \
  && apk del .build-deps
