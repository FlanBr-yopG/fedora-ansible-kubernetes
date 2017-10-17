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
[[ -d contrib ]] || git clone -q https://github.com/kubernetes/contrib.git
cd contrib/ansible/inventory
cp localhost.ini localhost.ini.bak
echo -e "[masters]\\nkube-master.vagrant\\n\\n[etcd]\\nkube-master.vagrant\\n\\n[nodes]" > localhost.ini
echo "kube-node01.vagrant" >> localhost.ini
echo "kube-node02.vagrant" >> localhost.ini
echo "kube-node03.vagrant" >> localhost.ini
echo -e "\\nansible_ssh_user: vagrant" >> group_vars/all.yml
[[ /root/.ssh/id_rsa ]] || {
  umask 0077
  cat /vagrant/kube-master-priv > /root/.ssh/id_rsa
  ssh-keygen -y -f /root/.ssh/id_rsa > /root/.ssh/id_rsa.pub
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  cat /root/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
}

#
