#!/bin/bash
function remove() {
    # Remove volume
    source variables
    # Remove images (Will remove all images that happens to have $NAME in it)
    docker rm --force $(docker ps -a | grep $NAME | awk '{print $1}')
    docker volume rm $INPUT_VOLUME
    docker volume rm $OUTPUT_VOLUME

}
while true; do
    read -p "Are you sure you want to remove all $NAME docker instances and volumes? " yn
    case $yn in
        [Yy]* ) remove; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
