#!/bin/bash

sudo su -c 'echo "192.168.50.4 OPENIDM_REPO_HOST" >> /etc/hosts'
sudo su -c 'echo "192.168.50.4 SQLFIDDLE_HOST" >> /etc/hosts'
sudo su -c 'echo "192.168.50.4 POSTGRESQL93_HOST" >> /etc/hosts'
sudo su -c 'echo "192.168.50.5 MYSQL56_HOST" >> /etc/hosts'

sudo apt-get update
sudo apt-get --yes --force-yes install python-software-properties
sudo add-apt-repository --yes ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get --yes --force-yes install oracle-java7-installer maven postgresql-client
cd /vagrant
mvn clean install
cd target/sqlfiddle
sudo -u vagrant nohup ./startup.sh &
