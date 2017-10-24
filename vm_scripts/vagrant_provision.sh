#!/bin/bash

dnf install -y ansible git python-netaddr
egrep '^# hosts v 0 0 1' /etc/hosts || {
  echo '10.251.240.100 kube-master.vagrant kube-master' >> /etc/hosts
  echo '10.251.240.101 kube-node01.vagrant kube-node01' >> /etc/hosts
  echo '10.251.240.102 kube-node02.vagrant kube-node02' >> /etc/hosts
  echo '10.251.240.103 kube-node03.vagrant kube-node03' >> /etc/hosts
  echo '# hosts v 0 0 1' >> /etc/hosts
}
set -ex
cd / ;
[[ -d ansi-kube ]] || mkdir ansi-kube ;
cd ansi-kube ;
[[ -d contrib ]] || {
  git clone -q https://github.com/kubernetes/contrib.git
  cd contrib/ansible/inventory
  echo -e "[masters]\\nkube-master.vagrant\\n\\n[etcd]\\nkube-master.vagrant\\n\\n[nodes]" > inventory
  echo "kube-node01.vagrant" >> inventory
  echo "kube-node02.vagrant" >> inventory
  echo "kube-node03.vagrant" >> inventory
  echo -e "\\nansible_ssh_user: vagrant" >> group_vars/all.yml
}
[[ -f /root/.ssh/id_rsa ]] || {
  umask 0077
  cat /vagrant/kube-master-priv > /root/.ssh/id_rsa
  ssh-keygen -y -f /root/.ssh/id_rsa > /root/.ssh/id_rsa.pub
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  cat /root/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
}
which kubectl || {
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  mv ./kubectl /usr/local/bin/kubectl
}

#