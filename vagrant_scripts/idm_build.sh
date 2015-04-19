#!/bin/bash

apt-get --yes --force-yes install maven npm

ln -s /usr/bin/nodejs /usr/bin/node
npm install -g grunt-cli

cd ~
wget -q http://dl.dropbox.com/u/2590603/bnd/biz.aQute.bnd.jar

# OSGi wrap the jTDS driver for SQL Server
wget -q http://central.maven.org/maven2/net/sourceforge/jtds/jtds/1.3.1/jtds-1.3.1.jar
java -jar ~/biz.aQute.bnd.jar wrap -properties /vagrant/vagrant_scripts/jtds.bnd ./jtds-1.3.1.jar
mv /vagrant/vagrant_scripts/jtds-1.3.1.bar ~/jtds-1.3.1.jar
mvn install:install-file -DgroupId=net.sourceforge.jtds -DartifactId=jtds -Dversion=1.3.1 -Dpackaging=jar -Dfile=./jtds-1.3.1.jar

# If you want to enable Oracle support, manually download ojdbc6.jar and put it in the root folder (up one level from here)
# Download it from here: http://www.oracle.com/technetwork/database/enterprise-edition/jdbc-112010-090769.html
# Afterwards, uncomment the dependency in ../pom.xml
if [ -e "/vagrant/ojdbc6.jar" ]
then
    java -jar ~/biz.aQute.bnd.jar wrap -properties /vagrant/vagrant_scripts/ojdbc6.bnd /vagrant/ojdbc6.jar
    mv /vagrant/vagrant_scripts/ojdbc6.bar ojdbc6.jar
    mvn install:install-file -DgroupId=com.oracle -DartifactId=ojdbc6 -Dversion=11.2.0.4 -Dpackaging=jar -Dfile=./ojdbc6.jar
fi


cd /vagrant
mvn clean install
npm install
cd target/sqlfiddle/bin
./create-openidm-rc.sh