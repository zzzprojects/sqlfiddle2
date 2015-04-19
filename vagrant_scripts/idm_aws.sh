#!/bin/bash

cd /vagrant

grunt sync less requirejs
update-rc.d openidm defaults
service varnish restart

if [ -d "/vagrant/vagrant_scripts/openvpn" ]
then

    apt-get --yes --force-yes install openvpn
    cp /vagrant/vagrant_scripts/openvpn/* /etc/openvpn

    echo "192.168.199.2   POSTGRESQL84_HOST" >> /etc/hosts
    echo "192.168.199.3   POSTGRESQL92_HOST" >> /etc/hosts
    echo "192.168.199.4   MYSQL51_HOST" >> /etc/hosts
    echo "192.168.199.5   POSTGRESQL94_HOST" >> /etc/hosts
    echo "192.168.199.6   MYSQL57_HOST" >> /etc/hosts
    echo "192.168.199.7   POSTGRESQL91_HOST" >> /etc/hosts
    service openvpn restart

fi

service openidm start