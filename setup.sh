#!/bin/bash
pushd /sys/devices/system/cpu
echo performance | tee cpu*/cpufreq/scaling_governor
popd
echo core >/proc/sys/kernel/core_pattern

docker build --tag afl:0.1 .
docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=1000 \
    output
docker run -v output:/output --detach afl:0.1
#docker run -v output:/output tengine_conf_fuzz:Dockerfile
