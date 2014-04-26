# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "postgresql93" do |postgresql93|
    postgresql93.vm.provision :shell, :path => "pg93_bootstrap.sh"
    postgresql93.vm.network "private_network", ip: "192.168.50.4"
    postgresql93.vm.network "forwarded_port", guest: 5432, host: 5432 
    postgresql93.vm.box = "hashicorp/precise32"
  end

  config.vm.define "mysql56" do |mysql56|
    mysql56.vm.provision :shell, :path => "my56_bootstrap.sh"
    mysql56.vm.network "private_network", ip: "192.168.50.5"
    mysql56.vm.network "forwarded_port", guest: 3306, host: 3306 
    mysql56.vm.box = "hashicorp/precise32"
  end

  config.vm.define "idm", primary: true do |idm|
    idm.vm.provision :shell, :path => "idm_bootstrap.sh"
    idm.vm.network "private_network", ip: "192.168.50.3"
    idm.vm.network "forwarded_port", guest: 8080, host: 8080
    idm.vm.network "forwarded_port", guest: 8443, host: 8443
    idm.vm.box = "hashicorp/precise32"
  end

end
