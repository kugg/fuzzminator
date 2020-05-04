FROM debian:stretch-slim

ARG URL=$URL

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
	strace \
        tcpdump \
        procps \
        vim \
    && git clone https://github.com/liangdzou/afl \
    && cd afl \
    && git checkout afl-2.39b \
    && make \
    && make install \
    && cd ..

# Target setup
RUN wget ${URL} \
    && dirname=$(tar -zxvf `basename ${URL}`| tail -n 1 |  cut -f 1 -d '/') \
    && echo "DIR=$dirname" >> ./env \
    && cd $dirname \
    && ./configure CC="afl-gcc" CXX="afl-g++" --disable-shared \
    && make \
    && make install \
    && apt-get clean && apt-get remove -y \
        libpcre++-dev \
        libssl-dev \
        zlib1g-dev \
        gcc \
        make \

# Fuzzer setup
COPY ./input /input/
RUN groupadd -r fuzz && useradd --no-log-init -r -g fuzz fuzz
RUN source ./env && chown fuzz:fuzz -R $DIR
USER fuzz:fuzz
CMD afl-fuzz $JOB -i /input -o /output -D 10 -t 90 -N tcp://127.0.0.1:8080 server
