#!/bin/bash

export OPENIDM_OPTS="-Xms128m -Xmx256m"
echo "export OPENIDM_OPTS=\"${OPENIDM_OPTS}\"" >> /etc/profile

echo "192.168.50.4 OPENIDM_REPO_HOST" >> /etc/hosts
echo "192.168.50.4 SQLFIDDLE_HOST" >> /etc/hosts
echo "192.168.50.4 POSTGRESQL93_HOST" >> /etc/hosts
echo "192.168.50.5 MYSQL56_HOST" >> /etc/hosts

apt-get --yes update
apt-get --yes upgrade

apt-get --yes --force-yes install openjdk-7-jdk maven npm varnish
ln -s /usr/bin/nodejs /usr/bin/node
npm install -g grunt-cli

cd /vagrant
mvn clean install
npm install
cd target/sqlfiddle/bin
./create-openidm-rc.sh
cp openidm /etc/init.d