# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# for aws provisioning, this assumes you have configured your aws provider elsewhere (~/.vagrant.d/Vagrantfile is a good choice)
# example of that config:
#
#Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
#
#  config.vm.provider "aws" do |aws, override|
#    aws.access_key_id = "YourAccessKeyId"
#    aws.secret_access_key = "YourSecretAccessKey"
#
#    aws.ami = "ami-29ebb519" #Ubuntu trusty 64bit (public)
#    aws.region = "us-west-2"
#    aws.availability_zone = "us-west-2b"
#    aws.instance_type = "t2.small"
#    aws.associate_public_ip = true
#    aws.subnet_id = "subnet-99999999"
#    aws.security_groups = "sg-99999999"
#    aws.keypair_name = "sqlfiddle2.pem"
#
#    override.vm.box = "dummy"
#    override.ssh.username = "ubuntu"
#    override.ssh.private_key_path = "/path/to/pem.pem"
#  end
#
#end


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.vm.box = "ubuntu/trusty64"
  end

  # VM for commercial databases (Oracle and SQL Server) running on a commercial OS (Windows 2008 Server)
  # Note that it is optional; it won't start up by default. If you want to start it, you have to manually call it like so:
  # vagrant up windows
  config.vm.define "windows", autostart: false do |windows|

    windows.vm.guest = "windows"
    windows.vm.boot_timeout = 600
    windows.vm.communicator = "winrm"

    windows.winrm.username = "Administrator"
    windows.winrm.password = "vagrant"

    windows.vm.provider "virtualbox" do |vb|
      vb.provision :shell, :path => "vagrant_scripts/windows_bootstrap.ps1"

      vb.network "private_network", ip: "10.0.0.16"
      vb.network :forwarded_port, guest: 3389, host: 3389
      vb.base_mac = "0800275A6A2B"

      # Provide the path to your virtualbox image which is running SQL Server 2014 and/or Oracle 11G XE:
      vb.box = "/Volumes/Virtual Disk Storage/jakefeasel.windows2008R2SQLServer2014Oracle11GXE.box"
    end

    # rsync to windows on aws doesn't seem to work, so don't bother (do the necessary provisioning before creating the ami)
    windows.vm.synced_folder ".", "/vagrant", disabled: true


    windows.vm.provider "aws" do |aws|
      aws.private_ip_address = "10.0.0.17"
      # is it expected that the ami has already executed the code in vagrant_scripts/windows_bootstrap.ps1
      aws.ami = "ami-892d0db9" # Windows Server 2008 w/ MS SQL 2014 Express and Oracle 11g XE (private)
    end

  end

  config.vm.define "postgresql93" do |postgresql93|
    postgresql93.vm.provision :shell, :path => "vagrant_scripts/pg93_bootstrap.sh"

    postgresql93.vm.provider "virtualbox" do |vb|
      vb.network "private_network", ip: "10.0.0.16"
    end

    postgresql93.vm.provider "aws" do |aws|
      aws.private_ip_address = "10.0.0.16"
    end
  end

  config.vm.define "mysql56" do |mysql56|
    mysql56.vm.provision :shell, :path => "vagrant_scripts/my56_bootstrap.sh"

    mysql56.vm.provider "virtualbox" do |vb|
      vb.network "private_network", ip: "10.0.0.15"
    end

    mysql56.vm.provider "aws" do |aws|
      aws.private_ip_address = "10.0.0.15"
    end
  end

  config.vm.define "idm", primary: true do |idm|

    idm.vm.provider "virtualbox" do |vb|
      vb.network "private_network", ip: "10.0.0.14"
      vb.network "forwarded_port", guest: 6081, host: 6081
      vb.network "forwarded_port", guest: 8080, host: 18080
      vb.network "forwarded_port", guest: 8443, host: 18443
    end

    idm.vm.provider "aws" do |aws|
      aws.private_ip_address = "10.0.0.14"
    end

    idm.vm.provision "shell", path: "vagrant_scripts/idm_bootstrap.sh"
    idm.vm.provision "shell", path: "vagrant_scripts/idm_startup.sh", run: "always"


  end

end
