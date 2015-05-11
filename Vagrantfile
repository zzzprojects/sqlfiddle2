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
      v.memory = 1024
      # Provide the path to your virtualbox image which is running SQL Server 2014 and/or Oracle 11G XE:
      override.vm.box = "~/jakefeasel.windows2008R2SQLServer2014Oracle11GXE.box"

      override.vm.provision :shell, :path => "vagrant_scripts/windows_bootstrap.ps1"

      override.vm.network "private_network", ip: "10.0.0.17"
      override.vm.network :forwarded_port, guest: 3389, host: 3389
    end

    windows.vm.provider "aws" do |aws, override|

      aws.private_ip_address = "10.0.0.17"
      # is it expected that the ami has already executed the code in vagrant_scripts/windows_bootstrap.ps1
      aws.ami = "ami-892d0db9" # Windows Server 2008 w/ MS SQL 2014 Express and Oracle 11g XE (private)

      # rsync to windows on aws doesn't seem to work, so don't bother (do the necessary provisioning before creating the ami)
      override.vm.synced_folder ".", "/vagrant", disabled: true

    end

  end


  config.vm.define "mysql56" do |mysql56|
    mysql56.vm.provision :shell, :path => "vagrant_scripts/my56_bootstrap.sh"
    mysql56.vm.box = "ubuntu/trusty64"
    mysql56.vm.network "private_network", ip: "10.0.0.15"

    mysql56.vm.provider "aws" do |aws|
      aws.private_ip_address = "10.0.0.15"
    end
  end

  config.vm.define "mysql55" do |mysql55|
    mysql55.vm.provision :shell, :path => "vagrant_scripts/my55_bootstrap.sh"
    mysql55.vm.box = "ubuntu/trusty64"
    mysql55.vm.network "private_network", ip: "10.0.0.18"

    mysql55.vm.provider "aws" do |aws|
      aws.instance_type = "t2.micro"
      aws.private_ip_address = "10.0.0.18"
    end
  end

  config.vm.define "postgresql93" do |postgresql93|
    postgresql93.vm.provision :shell, :path => "vagrant_scripts/pg93_bootstrap.sh"
    postgresql93.vm.box = "ubuntu/trusty64"
    postgresql93.vm.network "private_network", ip: "10.0.0.19"

    postgresql93.vm.provider "aws" do |aws|
      aws.instance_type = "t2.micro"
      aws.private_ip_address = "10.0.0.19"
    end
  end

  config.vm.define "appdb1" do |appdb1|
    appdb1.vm.provider "aws" do |aws, override|
      aws.private_ip_address = "10.0.0.16"
      aws.block_device_mapping = [{
        'VirtualName' => "postgresql_data",
        'DeviceName' => '/dev/sda1',
        'Ebs.VolumeSize' => 50,
        'Ebs.DeleteOnTermination' => true,
        'Ebs.VolumeType' => 'io1',
        'Ebs.Iops' => 500
      }]

      override.vm.provision :shell, :path => "vagrant_scripts/appdb_aws.sh"
    end

    appdb1.vm.provision :shell, :path => "vagrant_scripts/pg93_bootstrap.sh"
    appdb1.vm.provision :shell, :path => "vagrant_scripts/appdb_bootstrap.sh"
    appdb1.vm.box = "ubuntu/trusty64"
    appdb1.vm.network "private_network", ip: "10.0.0.16"
  end

  config.vm.define "appdb2", autostart: false do |appdb2|
    appdb2.vm.provider "aws" do |aws, override|
      aws.private_ip_address = "10.0.0.26"
      aws.block_device_mapping = [{
        'VirtualName' => "postgresql_data",
        'DeviceName' => '/dev/sda1',
        'Ebs.VolumeSize' => 50,
        'Ebs.DeleteOnTermination' => true,
        'Ebs.VolumeType' => 'io1',
        'Ebs.Iops' => 500
      }]

      override.vm.provision :shell, :path => "vagrant_scripts/appdb_aws.sh"
    end

    appdb2.vm.provision :shell, :path => "vagrant_scripts/pg93_bootstrap.sh"
    appdb2.vm.provision :shell, :path => "vagrant_scripts/appdb_bootstrap.sh"
    appdb2.vm.box = "ubuntu/trusty64"
    appdb2.vm.network "private_network", ip: "10.0.0.26"
  end

  config.vm.define "pgpool" do |pgpool|
    pgpool.vm.provision :shell, :path => "vagrant_scripts/pgpool_bootstrap.sh"
    pgpool.vm.box = "ubuntu/trusty64"
    pgpool.vm.network "private_network", ip: "10.0.0.20"

    pgpool.vm.provider "aws" do |aws|
      aws.instance_type = "t2.micro"
      aws.private_ip_address = "10.0.0.20"
    end
  end

  config.vm.define "idm", primary: true do |idm|

    idm.vm.box = "ubuntu/trusty64"
    idm.vm.network "private_network", ip: "10.0.0.14"
    idm.vm.network "forwarded_port", guest: 8080, host: 18080
    idm.vm.network "forwarded_port", guest: 80, host: 6081

    idm.vm.provider "aws" do |aws, override|
      aws.private_ip_address = "10.0.0.14"
      override.vm.provision :shell, :path => "vagrant_scripts/idm_aws.sh"

      # reboot instance every day at 4am server time
      override.vm.provision :shell, :inline => 'echo "0 4 * * *       /root/reboot-clean.sh >> /root/reboot.out 2>&1" | crontab'
    end

    idm.vm.provider "virtualbox" do |v, override|
      v.memory = 1024
      override.vm.provision :shell, path: "vagrant_scripts/idm_startup.sh", run: "always"
    end

    idm.vm.provision :shell, path: "vagrant_scripts/idm_prep.sh"
    idm.vm.provision :shell, path: "vagrant_scripts/idm_build.sh"
    idm.vm.provision :shell, :inline => "cp /vagrant/src/main/resources/conf/boot/boot.node1.properties /vagrant/target/sqlfiddle/conf/boot/boot.properties"
    idm.vm.provision :shell, :inline => "cp /vagrant/target/sqlfiddle/bin/openidm /etc/init.d"

  end

  config.vm.define "idm2", autostart: false do |idm2|

    idm2.vm.box = "ubuntu/trusty64"
    idm2.vm.network "private_network", ip: "10.0.0.24"
    idm2.vm.network "forwarded_port", guest: 8080, host: 28080

    idm2.vm.provision :shell, path: "vagrant_scripts/idm_prep.sh"

    idm2.vm.provider "aws" do |aws, override|
      aws.private_ip_address = "10.0.0.24"

      # In aws, we can reuse the build output from the main idm box, since everything is local to each machine. So we have to build again:
      override.vm.provision :shell, path: "vagrant_scripts/idm_build.sh"

      override.vm.provision :shell, :inline => "cp /vagrant/src/main/resources/conf/boot/boot.node2.properties /vagrant/target/sqlfiddle/conf/boot/boot.properties"
      override.vm.provision :shell, :inline => "cp /vagrant/target/sqlfiddle/bin/openidm /etc/init.d"
      override.vm.provision :shell, :path => "vagrant_scripts/idm_aws.sh"

      # reboot instance every day at 3am server time
      override.vm.provision :shell, :inline => 'echo "0 3 * * *       /root/reboot-clean.sh >> /root/reboot.out 2>&1" | crontab'
    end

    idm2.vm.provider "virtualbox" do |v, override|

      # when running virtualbox, we can use the built target from the main idm box to skip having to build it for this one
      # however, we don't want them to be shared when running, as that could cause conflicts with logs and what-not. A copy is best, so we just rsync:
      override.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git/"

      v.memory = 1024
      override.vm.provision :shell, :inline => "cp /vagrant/src/main/resources/conf/boot/boot.node2.properties /vagrant/target/sqlfiddle/conf/boot/boot.properties"
      override.vm.provision :shell, :inline => "cp /vagrant/target/sqlfiddle/bin/openidm /etc/init.d"
      override.vm.provision :shell, path: "vagrant_scripts/idm_startup.sh", run: "always"
    end

  end

end
