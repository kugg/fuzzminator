FROM debian:stretch-slim

ARG URL=http://nazgul.ch/dev/nostromo-1.9.7.tar.gz

RUN apt-get update && apt-get -y install \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        wget \
        gcc \
        git \
        make \
	socat \
	libcap2-bin \
	daemonize \
    && git clone https://github.com/liangdzou/afl \
    && cd afl \
    && git checkout afl-2.39b \
    && make \
    && make install \
    && cd ..

RUN wget ${URL} \
    && dirname=$(tar -zxvf `basename ${URL}`| tail -n 1 |  cut -f 1 -d '/') \
    && cd $dirname \
    && find . -name GNUmakefile -exec sed -i 's/cc\ /afl-gcc\ /g' {} + \
    && find . -name GNUmakefile -exec sed -i '/nhttpd.8/d' {} \; \
    && find . -name *.c -exec sed -i 's/fork()/0/g' {} + \
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
    && setcap 'cap_net_bind_service=+ep' `which nhttpd`

COPY ./input /input/
RUN daemonize `which socat` UNIX-LISTEN:/dev/log OPEN:/output/log.txt,creat,append
RUN groupadd -r user && useradd --no-log-init -r -g user user
USER user:user
CMD afl-fuzz $JOB -i /input -o /output -D 90 -t 30 -N tcp://127.0.0.1:80 nhttpd -c ./conf/nhttpd.conf-dist
#CMD ["afl-fuzz", "-M", "masterA:$ID/8", "-i", "/input", "-o", "/output", "-D", "90", "-t", "30", "-N", "tcp://127.0.0.1:80", "nhttpd", "-c", "./conf/nhttpd.conf-dist"]
