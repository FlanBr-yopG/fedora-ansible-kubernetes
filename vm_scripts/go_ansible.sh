#!/bin/bash

main() {
  getHostKey vagrant@kube-master.vagrant
  for i in 1 2 3 ; do
    getHostKey vagrant@kube-node0$i.vagrant
  done
  set -ex
  cd /ansi-kube/contrib/ansible/scripts && ./deploy-cluster.sh
}
getHostKey() {
  # ssh -v -o StrictHostKeyChecking=no -T "$@"
  local host=$1
  local justhost=$(echo $host | awk -F'@' '{print $NF}')
  [[ -z $justhost ]] || host=$justhost
  ssh-keygen -R $host
  ssh-keyscan $host >> ~/.ssh/known_hosts
}

main

#
