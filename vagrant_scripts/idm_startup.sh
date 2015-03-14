cd /vagrant
nohup grunt > target/grunt.log &
service openidm start
service varnish restart