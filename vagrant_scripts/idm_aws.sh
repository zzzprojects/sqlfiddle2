#!/bin/bash
if [ -d "./openvpn" ]
then

    apt-get --yes --force-yes install openvpn
    cp ./openvpn/* /etc/openvpn

    echo "192.168.199.2   POSTGRESQL84_HOST" >> /etc/hosts
    echo "192.168.199.3   POSTGRESQL92_HOST" >> /etc/hosts
    echo "192.168.199.4   MYSQL51_HOST" >> /etc/hosts
    echo "192.168.199.5   MYSQL55_HOST" >> /etc/hosts
    echo "192.168.199.6   MYSQL57_HOST" >> /etc/hosts
    echo "192.168.199.7   POSTGRESQL91_HOST" >> /etc/hosts
    service openvpn restart

fi