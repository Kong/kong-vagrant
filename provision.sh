#!/bin/bash

set -o errexit

KONG_VERSION=$@

echo "Installing Kong version: $KONG_VERSION"

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

# Install Kong
wget -O kong.deb https://github.com/Mashape/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.precise_all.deb
sudo apt-get install -y netcat openssl libpcre3 dnsmasq procps perl
sudo dpkg -i kong.deb
rm kong.deb

# Installing other dependencies
sudo apt-get install -y git curl make pkg-config unzip libpcre3-dev

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local

# Adjust PATH
export PATH=$PATH:/usr/local/bin:/usr/local/openresty/bin

# Adjust PATH for future ssh
echo "export PATH=\$PATH:/usr/local/bin:/usr/local/openresty/bin" >> /home/vagrant/.bashrc

sudo apt-get install redis-server
sudo chown vagrant /var/log/redis/redis-server.log

# Prepare path to lua librairies
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

# Create a Cassandra setup script
cat <<EOT >> /home/vagrant/cassandra2_setup.sh
# Install java runtime
echo Fetching and installing java...
sudo mkdir -p /usr/lib/jvm
sudo wget -q -O /tmp/jre-linux-x64.tar.gz --no-cookies --no-check-certificate --header 'Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jre-8u60-linux-x64.tar.gz
sudo tar zxvf /tmp/jre-linux-x64.tar.gz -C /usr/lib/jvm
sudo update-alternatives --install '/usr/bin/java' 'java' '/usr/lib/jvm/jre1.8.0_60/bin/java' 1
sudo update-alternatives --set java /usr/lib/jvm/jre1.8.0_60/bin/java

# install cassandra
echo Fetching and installing Cassandra...
echo 'deb http://debian.datastax.com/community stable main' | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
wget -q -O - '$@' http://debian.datastax.com/debian/repo_key | sudo apt-key add -
sudo apt-get update
sudo apt-get install cassandra=2.2.8 -y --force-yes
sudo /etc/init.d/cassandra restart
EOT

chmod +x /home/vagrant/cassandra2_setup.sh

echo "Successfully Installed Kong version: $KONG_VERSION, with Postgres."
echo 'To setup Cassandra 2.x use the script at "~/cassandra2_setup.sh".'
