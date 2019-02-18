# Stick to libressl 2.6
# https://github.com/PowerDNS/pdns/issues/6943
FROM alpine:3.7
MAINTAINER Christoph Wiechert <wio@psitrax.de>

ENV REFRESHED_AT="2018-11-09" \
    POWERDNS_VERSION=4.1.5 \
    MYSQL_AUTOCONF=true \
    MYSQL_HOST="192.168.100.8" \
    MYSQL_PORT="3306" \
    MYSQL_USER="powerdns" \
    MYSQL_PASS="" \
    MYSQL_DB="powerdns"

# alpine:3.8: mariadb-connector-c-dev

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    apk --update add libpq libstdc++ libgcc mariadb-client mariadb-client-libs && \
    apk add --virtual build-deps \
      g++ make mariadb-dev curl boost-dev && \
    curl -sSL https://downloads.powerdns.com/releases/pdns-$POWERDNS_VERSION.tar.bz2 | tar xj -C /tmp && \
    cd /tmp/pdns-$POWERDNS_VERSION && \
    ./configure --prefix="" --exec-prefix=/usr --sysconfdir=/etc/pdns \
      --with-modules="bind gmysql" --without-lua && \
    make && make install-strip && cd / && \
    mkdir -p /etc/pdns/conf.d && \
    addgroup -S pdns 2>/dev/null && \
    adduser -S -D -H -h /var/empty -s /bin/false -G pdns -g pdns pdns 2>/dev/null && \
    cp /usr/lib/libboost_program_options-mt.so* /tmp && \
    apk del --purge build-deps && \
    mv /tmp/libboost_program_options-mt.so* /usr/lib/ && \
    rm -rf /tmp/pdns-$POWERDNS_VERSION /var/cache/apk/*

ADD schema.sql pdns.conf /etc/pdns/
ADD entrypoint.sh /

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/entrypoint.sh"]
