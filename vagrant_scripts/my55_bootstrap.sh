#!/bin/bash

apt-get --yes update
apt-get --yes upgrade

mkdir -p /etc/mysql/conf.d
cp /vagrant/src/main/resources/db/mysql/my.cnf /etc/mysql/conf.d

echo mysql-server-5.5 mysql-server/root_password password password | sudo debconf-set-selections
echo mysql-server-5.5 mysql-server/root_password_again password password | sudo debconf-set-selections

apt-get --yes install mysql-server-5.5 mysql-client-5.5

echo "grant all privileges on *.* to root@'%' identified by 'password' with grant option;" | /usr/bin/mysql -u root -ppassword
