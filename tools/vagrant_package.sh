#!/bin/bash

# vagrant_clean.sh - clean the vagrant box to the point where you
# can safely take a snapshot for local caching
# Source: https://github.com/openstack-dev/devstack-vagrant

vagrant ssh controller1.openstack.dev -c "sudo su - stack -c 'cd /vagrant/devstack && ./clean.sh'"
vagrant ssh controller1.openstack.dev -c "sudo sed -i '/api/d' /etc/hosts"
vagrant ssh controller1.openstack.dev -c "echo '127.0.0.1 localhost' | sudo tee -a /etc/hosts"

VBOX_ID=$(VBoxManage list vms | grep 'devstack-vagrant-ansible_controller1openstackdev' | awk '{print $2}')
NAME=devstack-vagrant-`date +%Y%m%d`
vagrant package --base $VBOX_ID --output $NAME.box $NAME
