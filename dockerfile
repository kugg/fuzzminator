FROM debian:stretch-slim

ARG TENGINE_VERSION=2.3.0

EXPOSE 80 443

RUN apt-get update \
    && apt-get -y install \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        wget \
        gcc \
        make \
    && wget https://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz \
    && gunzip afl-latest.tgz \
    && tar xvf afl-latest.tar \
    && rm afl-latest.tar \
    && cd afl-* \
    && make \
    && make install \
    && cd .. \
    && wget https://github.com/alibaba/tengine/archive/${TENGINE_VERSION}.tar.gz \
    && tar -zxvf ${TENGINE_VERSION}.tar.gz && rm ${TENGINE_VERSION}.tar.gz \
    && mkdir /usr/local/nginx /var/tmp/nginx /var/log/nginx \
    && cd tengine-${TENGINE_VERSION} \
    && export CC="afl-gcc" \
    && export CXX="afl-g++" \
    && ./configure \
        --prefix=/usr/local/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --user=nginx \
        --group=nginx \
        --http-client-body-temp-path=/var/tmp/nginx/client \
        --http-proxy-temp-path=/var/tmp/nginx/proxy \
        --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
        --http-scgi-temp-path=/var/tmp/nginx/scgi \
        --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
        --with-ipv6 \
        --with-http_v2_module \
        --with-http_ssl_module \
    && make && make install \
    && cd ../ && rm -rf tengine-${TENGINE_VERSION} \
    && useradd -s /sbin/nologin nginx \
    && cd /usr/local/nginx \
    && chown nginx:nginx -R /usr/local/nginx/logs \
    && chown nginx:nginx -R /var/tmp/nginx \
    && chmod 700 -R /var/tmp/nginx \
    && chmod 777 -R /usr/local/nginx/logs \
    && ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx \
    && apt-get clean && apt-get remove -y \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        gcc \
        make

COPY tengine-${TENGINE_VERSION}/conf/nginx.conf /etc/nginx/
COPY tengine-${TENGINE_VERSION}/conf/nginx.conf /input/
COPY tengine-${TENGINE_VERSION}/html/index.html /etc/nginx/default/
COPY tengine-${TENGINE_VERSION}/packages/debian/nginx.vh.default.conf /etc/nginx/conf.d/

CMD ["afl-fuzz", "-M", "tfuzzer", "-i", "/input", "-o", "/output", "nginx", "-c", "@@"]
