#!/bin/bash

apt-get --yes update
apt-get --yes upgrade

apt-get --yes install libaio1

wget -q http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-community-server_5.6.21-1ubuntu14.04_amd64.deb
wget -q http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-community-client_5.6.21-1ubuntu14.04_amd64.deb
wget -q http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-common_5.6.21-1ubuntu14.04_amd64.deb

mkdir -p /etc/mysql/conf.d
cp /vagrant/src/main/resources/db/mysql/my.cnf /etc/mysql/conf.d

echo mysql-community-server mysql-community-server/root-pass password password | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/re-root-pass password password | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/remove-data-dir select false | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/remove-test-db select false | sudo debconf-set-selections
echo mysql-community-server mysql-community-server/data-dir select "" | sudo debconf-set-selections

dpkg -i  mysql-*.deb

echo "grant all privileges on *.* to root@'%' identified by 'password' with grant option;" | /usr/bin/mysql -u root -ppassword
