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

# Set higher ulimit
sudo bash -c 'echo "fs.file-max = 65536" >> /etc/sysctl.conf'
sudo sysctl -p
sudo bash -c "cat >> /etc/security/limits.conf" << EOL
* soft     nproc          65535
* hard     nproc          65535
* soft     nofile         65535
* hard     nofile         65535
EOL

echo "Successfully Installed Kong version: $KONG_VERSION"
