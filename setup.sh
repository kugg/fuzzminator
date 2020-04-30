#!/bin/bash
pushd /sys/devices/system/cpu
echo performance | tee cpu*/cpufreq/scaling_governor
popd
echo core >/proc/sys/kernel/core_pattern
source variables
docker build --tag $NAME:$VERSION .
docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=999 \
    $INPUT_VOLUME

docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=999 \
    $OUTPUT_VOLUME

for id in `seq 2 $(nproc)`; do
    docker run -v $INPUT_VOLUME:/$INPUT_VOLUME -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.$id --env JOB="-S $id" --env ID=$id --detach $NAME:$VERSION
done
docker run -v $INPUT_VOLUME:/$INPUT_VOLUME -v $OUTPUT_VOLUME:/$OUTPUT_VOLUME --name $NAME.1 --env JOB='-M master' --env ID=$id --detach $NAME:$VERSION
