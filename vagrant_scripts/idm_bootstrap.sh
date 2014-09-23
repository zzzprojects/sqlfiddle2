#!/bin/bash

echo "192.168.50.4 OPENIDM_REPO_HOST" >> /etc/hosts
echo "192.168.50.4 SQLFIDDLE_HOST" >> /etc/hosts
echo "192.168.50.4 POSTGRESQL93_HOST" >> /etc/hosts
echo "192.168.50.5 MYSQL56_HOST" >> /etc/hosts

apt-get --yes update

apt-get --yes --force-yes install python-software-properties
add-apt-repository --yes ppa:webupd8team/java
add-apt-repository --yes ppa:chris-lea/node.js

apt-get --yes update

echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

apt-get --yes --force-yes install oracle-java7-installer maven postgresql-client subversion nodejs varnish

npm install -g grunt-cli

#cd /tmp
#svn checkout https://svn.forgerock.org/openidm/tags/3.0.0 openidm
#cd openidm
#mvn clean install
cd /vagrant
mvn clean install
npm install
cd target/sqlfiddle/bin
./create-openidm-rc.sh
cp openidm /etc/init.d