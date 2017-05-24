#!/bin/bash

set -o errexit

KONG_VERSION=$1
CASSANDRA_VERSION=$2
if [ "$CASSANDRA_VERSION" = "2" ]; then
   CASSANDRA_VERSION=2.2.8
else
   CASSANDRA_VERSION=3.0.9
fi

echo "Installing Kong version: $KONG_VERSION"

# Installing other dependencies
sudo apt-get update
sudo apt-get install -y git curl make pkg-config unzip libpcre3-dev apt-transport-https

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local


####################
# Install Postgres #
####################
# Install Postgres
sudo apt-get update
sudo apt-get install -y software-properties-common python-software-properties
sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"
wget --quiet -O - https://postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - 
sudo apt-get update
sudo apt-get install -y postgresql-9.5

# Configure Postgres
sudo bash -c "cat > /etc/postgresql/9.5/main/pg_hba.conf" << EOL
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOL

sudo /etc/init.d/postgresql restart

# Create PG user and database
psql -U postgres <<EOF
\x
CREATE USER kong; 
CREATE DATABASE kong OWNER kong;
CREATE DATABASE kong_tests OWNER kong;
EOF

#################
# install redis #
#################
sudo apt-get update
sudo apt-get install redis-server
sudo chown vagrant /var/log/redis/redis-server.log

#####################
# install Cassandra #
######################
# Install java runtime (Cassandra dependency)
echo Fetching and installing java...
sudo mkdir -p /usr/lib/jvm
# https://gist.github.com/P7h/9741922
sudo wget -c -q -O "/tmp/jre-linux-x64.tar.gz" --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jre-8u131-linux-x64.tar.gz"
sudo tar zxvf /tmp/jre-linux-x64.tar.gz -C /usr/lib/jvm
sudo update-alternatives --install '/usr/bin/java' 'java' '/usr/lib/jvm/jre1.8.0_131/bin/java' 1
sudo update-alternatives --set java /usr/lib/jvm/jre1.8.0_131/bin/java

# install cassandra
echo Fetching and installing Cassandra...
echo 'deb http://debian.datastax.com/community stable main' | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
wget -q -O - '$@' http://debian.datastax.com/debian/repo_key | sudo apt-key add -
sudo apt-get update
sudo apt-get install cassandra=$CASSANDRA_VERSION -y --force-yes
sudo /etc/init.d/cassandra restart

################
# Install Kong #
################
echo Fetching and installing Kong...
wget -q -O kong.deb https://github.com/Mashape/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.precise_all.deb
sudo apt-get update
sudo apt-get install -y netcat openssl libpcre3 dnsmasq procps perl
sudo dpkg -i kong.deb
rm kong.deb

# Adjust PATH
export PATH=$PATH:/usr/local/bin:/usr/local/openresty/bin

# Prepare path to lua libraries
ln -sfn /usr/local /home/vagrant/.luarocks

# Set higher ulimit
sudo bash -c 'echo "fs.file-max = 65536" >> /etc/sysctl.conf'
sudo sysctl -p
sudo bash -c "cat >> /etc/security/limits.conf" << EOL
* soft     nproc          65535
* hard     nproc          65535
* soft     nofile         65535
* hard     nofile         65535
EOL


#############
# Finish... #
#############

# Adjust PATH for future ssh
echo "export PATH=\$PATH:/usr/local/bin:/usr/local/openresty/bin" >> /home/vagrant/.bashrc

# Adjust LUA_PATH to find the plugin dev setup
echo "export LUA_PATH=\"/kong-plugin/?.lua;/kong-plugin/?/init.lua;;\"" >> /home/vagrant/.bashrc

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local

echo "Successfully Installed Kong version: $KONG_VERSION"
