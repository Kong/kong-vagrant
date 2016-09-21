#!/bin/bash

KONG_VERSION=$@

echo "Installing Kong version: $KONG_VERSION"

sudo bash -c "echo 'nameserver 10.0.2.3' >> /etc/resolv.conf"

# Adding Datastax Yum repo
sudo bash -c "cat >> /etc/yum.repos.d/datastax.repo" << EOL
[datastax] 
name = DataStax Repo for Apache Cassandra
baseurl = https://rpm.datastax.com/community
enabled = 1
gpgcheck = 0
EOL

# Installing Cassandra
sudo yum install -y java-1.8.0 cassandra22
sudo /etc/init.d/cassandra restart
sudo chmod 777 -R /var/lib/cassandra
sudo /etc/init.d/cassandra restart

# Installing other dependencies
sudo yum install -y wget tar make curl ldconfig gcc pcre-devel openssl-devel unzip git

# Installing Kong
sudo yum install -y https://github.com/Mashape/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.el7.noarch.rpm

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local

# Adjust PATH
export PATH=$PATH:/usr/local/bin

echo "Successfully Installed Kong version: $KONG_VERSION"
