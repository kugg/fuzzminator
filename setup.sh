#!/bin/bash
pushd /sys/devices/system/cpu
echo performance | tee cpu*/cpufreq/scaling_governor
popd
echo core >/proc/sys/kernel/core_pattern
source variables

docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=1000 \
    $INPUT_VOLUME

docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=1000 \
    $OUTPUT_VOLUME

docker build --tag $NAME:$VERSION .

for id in `seq 2 $(nproc)`; do
    docker run -v $INPUT_VOLUME:/$INPUT_VOLUME -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.$id --env URL=$url --env JOB="-S $id" --env ID=$id --detach $NAME:$VERSION
done
docker run -v $INPUT_VOLUME:/$INPUT_VOLUME -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.1 --env URL=$url --env JOB='-M master' --env ID=$id --detach $NAME:$VERSION

# Post installation fix for a bug in rsyslog caused by systemd.
for id in `seq 1 $(nproc)`; do
    docker exec -d --user root afl.$id /etc/init.d/rsyslog restart
done
