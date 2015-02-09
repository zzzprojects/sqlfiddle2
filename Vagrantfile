# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # VM for commercial databases (Oracle and SQL Server) running on a commercial OS (Windows 2008 Server)
  # Note that it is optional; it won't start up by default. If you want to start it, you have to manually call it like so:
  # vagrant up windows
  config.vm.define "windows", autostart: false do |windows|
    windows.vm.provision :shell, :path => "vagrant_scripts/windows_bootstrap.ps1"
    windows.vm.boot_timeout = 600
    windows.vm.network "private_network", ip: "192.168.50.6"
    windows.vm.communicator = "winrm"

    windows.winrm.username = "Administrator"
    windows.winrm.password = "vagrant"

    windows.vm.network :forwarded_port, guest: 3389, host: 3389
    windows.vm.base_mac = "0800275A6A2B"

    # Provide the path to your virtualbox image which is running SQL Server 2014 and/or Oracle 11G XE:
    windows.vm.box = "/Volumes/Virtual Disk Storage/jakefeasel.windows2008R2SQLServer2014Oracle11GXE.box"
  end

  config.vm.define "postgresql93" do |postgresql93|
    postgresql93.vm.provision :shell, :path => "vagrant_scripts/pg93_bootstrap.sh"
    postgresql93.vm.network "private_network", ip: "192.168.50.4"
    postgresql93.vm.box = "ubuntu/trusty64"
  end

  config.vm.define "mysql56" do |mysql56|
    mysql56.vm.provision :shell, :path => "vagrant_scripts/my56_bootstrap.sh"
    mysql56.vm.network "private_network", ip: "192.168.50.5"
    mysql56.vm.box = "ubuntu/trusty64"
  end

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end

  config.vm.define "idm", primary: true do |idm|

    idm.vm.provision "shell", path: "vagrant_scripts/idm_bootstrap.sh"
    idm.vm.provision "shell", path: "vagrant_scripts/idm_startup.sh", run: "always"

    idm.vm.network "private_network", ip: "192.168.50.3"
    idm.vm.network "forwarded_port", guest: 6081, host: 6081
    idm.vm.network "forwarded_port", guest: 8080, host: 18080
    idm.vm.network "forwarded_port", guest: 8443, host: 18443
    idm.vm.box = "ubuntu/trusty64"
  end

end
