FROM debian:stretch-slim

ARG URL=https://github.com/kugg/fuzzample/archive/demo.tar.gz

# Standard setup
RUN apt-get update && apt-get -y install \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        wget \
        gcc \
        git \
        make \
	strace \
        tcpdump \
        procps \
        nano \
        autoconf \
        automake \
        autotools-dev \
    && git clone https://github.com/liangdzou/afl \
    && cd afl \
    && git checkout afl-2.39b \
    && make \
    && make install

# Target setup
RUN wget ${URL} \
    && dirname=$(tar -zxvf `basename ${URL}`| tail -n 1 |  cut -f 1 -d '/') \
    && echo "DIR=$dirname" >> ./env \
    && cd $dirname \
    && autoreconf -vif \
    && ./configure CC="afl-gcc" CXX="afl-g++" \
    && make \
    && make install

# Fuzzer setup
COPY ./input /input/
RUN groupadd -r fuzz && useradd --no-log-init -r -g fuzz fuzz
RUN . ./env && chown fuzz:fuzz -R $DIR
USER fuzz:fuzz
CMD afl-fuzz $JOB -i /input -o /output -D 10 -t 90 -N tcp://127.0.0.1:9034 server
