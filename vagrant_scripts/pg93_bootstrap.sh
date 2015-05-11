#!/bin/bash

# create a 512mb swapfile
dd if=/dev/zero of=/swapfile1 bs=1024 count=524288
chown root:root /swapfile1
chmod 0600 /swapfile1
mkswap /swapfile1
swapon /swapfile1
echo "/swapfile1 none swap sw 0 0" >> /etc/fstab

export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get --yes update
apt-get --yes upgrade
apt-get --yes --force-yes install postgresql-9.3 postgresql-contrib-9.3 postgresql-9.3-pgpool2

pg_dropcluster --stop 9.3 main
echo "listen_addresses = '*'" >> /etc/postgresql-common/createcluster.conf
echo "max_connections = 500" >> /etc/postgresql-common/createcluster.conf
pg_createcluster --start -e UTF-8 --locale en_US.UTF-8 9.3 main -- --auth-local=trust
echo "host    all             all             10.0.0.14/32            md5" >> /etc/postgresql/9.3/main/pg_hba.conf
echo "host    all             all             10.0.0.24/32            md5" >> /etc/postgresql/9.3/main/pg_hba.conf
echo "host    all             all             192.168.50.0/24            md5" >> /etc/postgresql/9.3/main/pg_hba.conf
service postgresql reload

echo "alter user postgres with password 'password';" | psql -U postgres
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT

# initialize the template database, used by fiddle databases running in this env
psql -U postgres postgres < /vagrant/src/main/resources/db/postgresql/initial_setup.sql
psql -U postgres db_template < /vagrant/src/main/resources/db/postgresql/db_template.sql

