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

docker build --build-arg URL=$URL --tag $NAME:$VERSION .
# Set up env variables using --env-file ./variables instead
for id in `seq 2 $(nproc)`; do
    docker run -it -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.$id --env-file ./variables --env JOB="-S $id" --env ID=$id --detach $NAME:$VERSION
    #docker run -it -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.$id --env TARGET=$TARGET --env URL=$URL --env JOB="-S $id" --env ID=$id --detach $NAME:$VERSION
done
docker run -it -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.1 --env-file ./variables --env JOB="-M master" --env ID=$id --detach $NAME:$VERSION

# Post installation fix for a bug in rsyslog caused by systemd.
# for id in `seq 1 $(nproc)`; do
#    docker exec -d --user root $NAME.$id /etc/init.d/rsyslog restart
# done
