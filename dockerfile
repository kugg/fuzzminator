FROM debian:stretch-slim

ARG URL=http://nazgul.ch/dev/nostromo-1.9.7.tar.gz

# Standard setup
RUN apt-get update && apt-get -y install \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        wget \
        gcc \
        git \
        make \
        rsyslog \
    && git clone https://github.com/liangdzou/afl \
    && cd afl \
    && git checkout afl-2.39b \
    && make \
    && make install \
    && cd ..

# Target setup
RUN wget ${URL} \
    && dirname=$(tar -zxvf `basename ${URL}`| tail -n 1 |  cut -f 1 -d '/') \
    && cd $dirname \
    && find . -name GNUmakefile -exec sed -i 's/cc\ /afl-gcc\ /g' {} + \
    && find . -name GNUmakefile -exec sed -i '/nhttpd.8/d' {} \; \
    && find . -name *.c -exec sed -i 's/fork()/0/g' {} + \
    && sed -i 's/80/8080/g' src/nhttpd/config.h \
    && make \
    && make install \
    && apt-get clean && apt-get remove -y \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        gcc \
        make \
    && sed -i s"/_nostromo/user/g" conf/nhttpd.conf-dist \
    && sed -i s"#/var/nostromo/#$PWD#" conf/nhttpd.conf-dist \
    && echo 'syssock.use="on"' > /etc/rsyslog.d/nostromo.conf \
    && mkdir logs \
RUN /etc/init.d/rsyslog restart # Work around rsyslog bug that fails to create socket unless restarted.

# Fuzzer setup
COPY ./input /input/
RUN groupadd -r user && useradd --no-log-init -r -g user user
RUN chown user:user nostromo-1.9.7 # Make this an external environment thing, also if a host os user is named user the UID and GID of that user will be used. Seriously!?
USER user:user
CMD afl-fuzz $JOB -i /input -o /output -D 90 -t 30 -N tcp://127.0.0.1:8080 nhttpd -c ./conf/nhttpd.conf-dist
