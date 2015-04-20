#!/bin/bash


cd /vagrant

grunt sync less requirejs
update-rc.d openidm defaults
service varnish restart

if [ -e "/vagrant/vagrant_scripts/awsconfig" ]
then
    apt-get --yes --force-yes install awscli
    mkdir -p ~/.aws
    cp -R /vagrant/vagrant_scripts/awsconfig ~/.aws/config
    chmod 600 ~/.aws/config

    aws elb register-instances-with-load-balancer --load-balancer-name sqlfiddle-web --instances `ec2metadata --instance-id`


#########################################
cat << REBOOTCLEAN > ~/reboot-clean.sh
#!/bin/sh

# 1) Note that I've named the load-balancer sqlfiddle-web in my AWS config
# 2) This command de-registers this instance from the load balancer
aws elb deregister-instances-from-load-balancer --load-balancer-name sqlfiddle-web --instances `ec2metadata --instance-id`
service openidm stop
reboot
REBOOTCLEAN
#########################################

    chmod +x ~/reboot-clean.sh

#########################################
cat << DELAYEDSTARTUP > /etc/rc.local
#!/bin/sh

# five minutes should be enough time for the system to be ready to start processing requests
sleep 300
aws elb register-instances-with-load-balancer --load-balancer-name sqlfiddle-web --instances `ec2metadata --instance-id`
exit 0

DELAYEDSTARTUP
#########################################


fi

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