
echo "10.0.0.16 APPDB1" >> /etc/hosts
echo "10.0.0.26 APPDB2" >> /etc/hosts


apt-get --yes update
apt-get --yes upgrade
apt-get --yes --force-yes install pgpool2=3.3.2-1ubuntu1 libpgpool0=3.3.2-1ubuntu1

cp /vagrant/src/main/resources/db/sqlfiddle/pgpool.conf /etc/pgpool2/pgpool.conf


echo postgres:`pg_md5 password` >> /etc/pgpool2/pcp.conf
echo "host    all             all             10.0.0.14/32            trust" >> /etc/pgpool2/pool_hba.conf
echo "host    all             all             10.0.0.24/32            trust" >> /etc/pgpool2/pool_hba.conf

mkdir /APPDB1_data
mkdir /APPDB2_data

chown postgres /APPDB*_data

service pgpool2 restart