FROM alpine:3.8

RUN set -ex \
  && apk add \
    cyrus-sasl \
    openssl \
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
  && make install
