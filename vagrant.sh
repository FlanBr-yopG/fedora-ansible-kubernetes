#!/bin/bash

main() {
  set -ex
  [[ quick == $1 ]] || {
    vagrant reload
    vagrant up
  }
  [[ -f ./kube-master-priv ]] || cp ./.vagrant/machines/kube-master/virtualbox/private_key ./kube-master-priv
  vagrant provision
  sleep 120;
  vagrant ssh -c "sudo bash /vagrant/vm_scripts/go_ansible.sh"
}
final() {
  nohup bash -c "sleep 120; rm -f ./kube-master-priv" &> ./nohup1.log &
  echo "NOTE: Scheduled final() cleanup." 1>&2
}

trap final EXIT
main "$@"

#
