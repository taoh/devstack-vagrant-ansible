devstack-vagrant-ansible
================

Build devstack environment for local development and testing using Vagrant+Ansible


Vagrant Setup
------------------------
* Install vagrant if not installed yet
* `cp config.yaml.example config.yaml`
* Modify cluster information in config.yaml
* Run `vagrant up`. It takes an hour or so to fully provision the box.

What you should get
------------------------
* 1 node devstack at controller1.openstack.dev
* you can open Horizon at http://controller1.openstack.dev (or http://[controller_hostname] if you have changed it in config.yaml)
* ssh into the box: `vagrant ssh`
* the source code of devstack and openstack is now shared at your local folder
