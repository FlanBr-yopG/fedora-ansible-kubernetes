#!/bin/bash

dnf install -y ansible git python-netaddr
egrep '^# hosts v 0 0 1' /etc/hosts || {
  {
    echo '10.251.240.100 kube-master.vagrant kube-master'
    echo '10.251.240.101 kube-node01.vagrant kube-node01'
    echo '10.251.240.102 kube-node02.vagrant kube-node02'
    echo '10.251.240.103 kube-node03.vagrant kube-node03'
    echo '# hosts v 0 0 1'
  } >> /etc/hosts
}
dnf install -y jq
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
} > /tmp/kubernetes_contrib_ansible_inventory.log 2>&1
[[ -f /root/.ssh/id_rsa ]] || {
  umask 0077
  [[ -e /vagrant/kube-master-priv ]] \
  || cp /vagrant/.vagrant/machines/kube-master/virtualbox/private_key /vagrant/kube-master-priv
  cat /vagrant/kube-master-priv > /root/.ssh/id_rsa
  ssh-keygen -y -f /root/.ssh/id_rsa > /root/.ssh/id_rsa.pub
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  cat /root/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
} > /tmp/id_rsa.fix.log 2>&1
export PATH="$PATH:/usr/local/bin"
which kubectl || {
  curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  mv ./kubectl /usr/local/bin/kubectl
} > /tmp/kubectl.fix.log 2>&1
yum list installed docker || yum -y install docker > /tmp/yum_install_docker.log 2>&1
systemctl status rhel-push-plugin.socket | egrep '^ *Active: active \((listening|running)\)' || {
  yum -y remove container-selinux ;
  yum -y install container-selinux ;
  systemctl start rhel-push-plugin.socket;
  sleep 5;
  systemctl status rhel-push-plugin.socket | egrep '^ *Active: active \((listening|running)\)'
  systemctl enable docker
  systemctl start docker
  systemctl status docker | egrep '^ *Active: active \(running\)'
} > /tmp/rhel-push-plugin.socket.fix.log 2>&1

#
