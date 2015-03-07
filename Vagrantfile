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

    windows.vm.provider "virtualbox" do |v, override|
      # Provide the path to your virtualbox image which is running SQL Server 2014 and/or Oracle 11G XE:
      override.vm.box = "/Volumes/Virtual Disk Storage/jakefeasel.windows2008R2SQLServer2014Oracle11GXE.box"

      override.vm.provision :shell, :path => "vagrant_scripts/windows_bootstrap.ps1"

      override.vm.network "private_network", ip: "10.0.0.17"
      override.vm.network :forwarded_port, guest: 3389, host: 3389
      override.vm.base_mac = "0800275A6A2B"
    end

    windows.vm.provider "aws" do |aws, override|

      aws.private_ip_address = "10.0.0.17"
      # is it expected that the ami has already executed the code in vagrant_scripts/windows_bootstrap.ps1
      aws.ami = "ami-892d0db9" # Windows Server 2008 w/ MS SQL 2014 Express and Oracle 11g XE (private)

      # rsync to windows on aws doesn't seem to work, so don't bother (do the necessary provisioning before creating the ami)
      override.vm.synced_folder ".", "/vagrant", disabled: true

    end

  end

  config.vm.define "postgresql93" do |postgresql93|
    postgresql93.vm.provider "aws" do |aws, override|
      aws.private_ip_address = "10.0.0.16"
      aws.block_device_mapping = [{
        'VirtualName' => "postgresql_data",
        'DeviceName' => '/dev/sda1',
        'Ebs.VolumeSize' => 50,
        'Ebs.DeleteOnTermination' => true,
        'Ebs.VolumeType' => 'io1',
        'Ebs.Iops' => 500
      }]
    end

    postgresql93.vm.provision :shell, :path => "vagrant_scripts/pg93_bootstrap.sh"
    postgresql93.vm.box = "ubuntu/trusty64"
    postgresql93.vm.network "private_network", ip: "10.0.0.16"
  end

  config.vm.define "mysql56" do |mysql56|
    mysql56.vm.provision :shell, :path => "vagrant_scripts/my56_bootstrap.sh"
    mysql56.vm.box = "ubuntu/trusty64"
    mysql56.vm.network "private_network", ip: "10.0.0.15"

    mysql56.vm.provider "aws" do |aws|
      aws.private_ip_address = "10.0.0.15"
    end
  end

  config.vm.define "idm", primary: true do |idm|

    idm.vm.box = "ubuntu/trusty64"
    idm.vm.network "private_network", ip: "10.0.0.14"
    idm.vm.network "forwarded_port", guest: 80, host: 6081
    idm.vm.network "forwarded_port", guest: 8080, host: 18080
    idm.vm.network "forwarded_port", guest: 8443, host: 18443

    idm.vm.provider "aws" do |aws, override|
      aws.private_ip_address = "10.0.0.14"
      override.vm.provision :shell, :path => "vagrant_scripts/idm_aws.sh"
    end

    idm.vm.provision "shell", path: "vagrant_scripts/idm_bootstrap.sh"
    idm.vm.provision "shell", path: "vagrant_scripts/idm_startup.sh", run: "always"


  end

end
