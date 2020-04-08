FROM debian:stretch-slim

ARG URL=http://nazgul.ch/dev/nostromo-1.9.7.tar.gz

EXPOSE 80 443

RUN apt-get update \
    && apt-get -y install \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        wget \
        gcc \
        git \
        make \
    && git clone https://github.com/liangdzou/afl \
    && cd afl \
    && git checkout afl-2.39b \
    && make \
    && make install \
    && cd .. \
    && wget ${URL} \
    && dirname=$(tar -zxvf `basename ${URL}`| tail -n 1 |  cut -f 1 -d '/') \
    && cd $dirname \
    && find . -name GNUmakefile -exec sed -i 's/cc\ /afl-gcc\ /g' {} + \
    && sed -i '/nroff/d' ./src/nhttpd/GNUmakefile \
    && make \
    && make install \
    && apt-get clean && apt-get remove -y \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        gcc \
        make \
    && sed -i s"/_nostromo/root/g" conf/nhttpd.conf-dist \
    && sed -i s"#/var/nostromo/#$PWD#" conf/nhttpd.conf-dist \
    && mkdir input/ \
    && echo -e "GET /index.html HTTP/1.0\r\n" > ./input/getrequest

COPY input /input/

CMD ["afl-fuzz", "-M", "masterA:1/1", "-i", "/input", "-o", "/output", "-D", "10", "-t", "10", "-N", "tcp://127.0.0.1:80", "nhttpd -c ./conf/nhttpd.conf-dist"]
