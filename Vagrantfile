# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2" if not defined? VAGRANTFILE_API_VERSION

require 'yaml'
if File.file?('config.yaml')
  conf = YAML.load_file('config.yaml')
else
  raise "Configuration file 'config.yaml' does not exist."
end

cluster = conf['cluster']
controller_nodes = cluster['controller_nodes']
compute_nodes = cluster['compute_nodes'] || []

if controller_nodes.nil? || controller_nodes.size == 0
  raise "Must define at least one controller node in config.yaml"
end

def configure_vm(node, vm, conf)
  vm.hostname = node['hostname']
  vm.network :private_network, ip: "#{node['ip']}"

  vm.provider :virtualbox do |vb|
    # you need this for openstack guests to talk to each other
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "#{node['memory']}"]
    vb.customize ["modifyvm", :id, "--cpus", "#{node['cpu']}"]
    # if specified assign a static MAC address
    if node["mac_address"]
      vb.customize ["modifyvm", :id, "--macaddress2", node["mac_address"]]
    end
  end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = conf['box_name'] || 'ubuntu/trusty64'
  config.vm.box_url = conf['box_url'] if conf['box_url']

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
  end

  # NOTE(berendt): This solves the Ubuntu-specific Vagrant issue 1673.
  #                https://github.com/mitchellh/vagrant/issues/1673
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  cluster['controller_nodes'].each_with_index do |node, index|
    config.vm.define node['hostname'] do |controller|
      configure_vm(node, controller.vm, conf)
      controller.vm.network "forwarded_port", guest: 80, host: (9020+index), host_ip: "127.0.0.1"
      controller.vm.network "forwarded_port", guest: 6080, host: (9080+index), host_ip: "127.0.0.1"

      # provision nodes with ansible - only run this as last vm
      if index == controller_nodes.size - 1
        controller.vm.provision :ansible do |ansible|
          ansible.groups = {
            "controllers" => controller_nodes.collect{|x| x['hostname']},
            "computes" => compute_nodes.collect{|x| x['hostname']},
            "all_groups:children" => ["controllers", "computes"],
          }
          ansible.verbose = "vvvv"
          ansible.playbook = "provision/cluster.yml"
          ansible.limit = 'all'# "#{node[:ip]}" # Ansible hosts are identified by ip
        end # end provision

        # for some reason, ansible shell command doesn't output stdout nicely so we resort to a shell provisioner
        controller.vm.provision "shell",
          inline: "/vagrant/devstack/stack.sh 2>&1 | tee /opt/stack/logs/stack.sh.log",
          keep_color: false,
          privileged: false
      end #end if
    end
  end

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true
end
