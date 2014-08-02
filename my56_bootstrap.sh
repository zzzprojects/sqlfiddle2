#!/bin/bash

echo mysql-community-server mysql-community-server/root-pass password password | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/re-root-pass password password | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/remove-data-dir select false | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/remove-test-db select false | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/data-dir select "" | sudo debconf-set-selections

apt-get -y update

apt-get -y install libaio1

wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-community-client_5.6.20-1ubuntu12.04_i386.deb
wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-community-server_5.6.20-1ubuntu12.04_i386.deb
wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-common_5.6.20-1ubuntu12.04_i386.deb

mkdir -p /etc/mysql/conf.d
cp /vagrant/src/main/resources/db/mysql/my.cnf /etc/mysql/conf.d

dpkg -i  mysql-*.deb

echo "grant all privileges on *.* to root@'%' identified by 'password' with grant option;" | /usr/bin/mysql -u root -ppassword
