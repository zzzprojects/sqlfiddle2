#!/bin/bash

apt-get -y update
wget -q http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.17-debian6.0-i686.deb
dpkg -i  mysql-*.deb
cp /opt/mysql/server-5.6/support-files/mysql.server /etc/init.d/mysql.server && update-rc.d mysql.server defaults
apt-get -y install libaio1
groupadd mysql
useradd mysql -g mysql
chown -R mysql /opt/mysql/server-5.6/
chgrp -R mysql /opt/mysql/server-5.6/
/opt/mysql/server-5.6/scripts/mysql_install_db --user=mysql --datadir=/var/lib/mysql
cp /vagrant/src/main/resources/db/mysql/my.cnf /etc
rm /opt/mysql/server-5.6/my.cnf
service mysql.server start
echo 'export PATH=/opt/mysql/server-5.6/bin:$PATH' > ~vagrant/.bash_profile
echo "grant all privileges on *.* to root@'%' identified by 'password' with grant option;" | /opt/mysql/server-5.6/bin/mysql -u root