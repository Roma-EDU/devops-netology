#!/bin/bash

echo Launching docker containers...
existing_containers=$(docker container ls -a)
if [[ $existing_containers == *"ubuntu"* ]]; then
  docker container start ubuntu
else
  docker start -itd --name ubuntu 42a4e3b21923
fi
if [[ $existing_containers == *"centos7"* ]]; then
  docker container start centos7
else
  docker start -itd --name centos7 42a4e3b21923
fi

echo Launching ansible playbook...
ansible-playbook -i inventory/prod.yml site.yml --ask-vault-pass

echo Stopping docker containers...
docker container stop ubuntu centos7

echo All done!