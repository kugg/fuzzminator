pushd /sys/devices/system/cpu
echo performance | tee cpu*/cpufreq/scaling_governor
popd
echo core >/proc/sys/kernel/core_pattern

sudo docker build --tag afl_tengine:1.0 .
sudo docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=1000 \
    output
sudo docker run -v output:/output --detach afl_tengine:1.0
sudo docker run -v output:/output tengine_conf_fuzz:Dockerfile

