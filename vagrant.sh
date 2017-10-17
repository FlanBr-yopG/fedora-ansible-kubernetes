#!/bin/bash

main() {
  set -ex
  vagrant reload
  vagrant up
  [[ -f ./kube-master-priv ]] || cp ./.vagrant/machines/kube-master/virtualbox/private_key ./kube-master-priv
  vagrant provision
}
final() {
  nohup bash -c "sleep 120; rm -f ./kube-master-priv" &> ./nohup1.log &
  echo "NOTE: Scheduled final() cleanup." 1>&2
}

main

#
