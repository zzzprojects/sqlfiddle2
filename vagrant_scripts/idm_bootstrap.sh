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

# If you want to enable Oracle support, manually download ojdbc6.jar and put it in the root folder (up one level from here)
# Download it from here: http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
# Afterwards, uncomment the below line as well as the dependency in ../pom.xml
#mvn install:install-file -DgroupId=com.oracle -DartifactId=ojdbc6 -Dversion=11.2.0.4 -Dpackaging=jar -Dfile=/vagrant/ojdbc6.jar

cd /vagrant
mvn clean install
npm install
cd target/sqlfiddle/bin
./create-openidm-rc.sh
cp openidm /etc/init.d