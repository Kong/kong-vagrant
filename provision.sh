#!/bin/bash

set -o errexit

#Stop the STDin warnings
export DEBIAN_FRONTEND=noninteractive


# parse/set up input parameters

KONG_VERSION=$1
CASSANDRA_VERSION=$2
KONG_UTILITIES=$3
ANREPORTS=$4
LOGLEVEL=$5

VERSION_RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
KONG_MAJOR=$(echo $1 | sed -e "s#$VERSION_RE#\1#")
KONG_MINOR=$(echo $1 | sed -e "s#$VERSION_RE#\2#")
KONG_PATCH=$(echo $1 | sed -e "s#$VERSION_RE#\3#")
let "KONG_NUM_VERSION = KONG_MAJOR * 10000 + KONG_MINOR * 100 + KONG_PATCH"

echo "*************************************************************************"
echo "Installing Kong version: $KONG_VERSION"
echo "*************************************************************************"


if [ "$CASSANDRA_VERSION" = "2" ]; then
   CASSANDRA_VERSION=2.2.8
else
   CASSANDRA_VERSION=3.0.9
fi

POSTGRES_VERSION=9.5

#Set some version dependent options

KONG_DOWNLOAD_URL="https://github.com/Kong/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.precise_all.deb"
KONG_ADMIN_LISTEN="0.0.0.0:8001"
KONG_ADMIN_LISTEN_SSL="0.0.0.0:8444"

if [ $KONG_NUM_VERSION -gt 001003 ]; then
  #Kong 0.10.4 and later are on Bintray
  KONG_DOWNLOAD_URL="https://bintray.com/kong/kong-community-edition-deb/download_file?file_path=dists%2Fkong-community-edition-${KONG_VERSION}.trusty.all.deb"
fi

if [ $KONG_NUM_VERSION -ge 001300 ]; then
  #Kong 0.13.0 listen directives format changed, now combined
  KONG_ADMIN_LISTEN="0.0.0.0:8001, 0.0.0.0:8444 ssl"
  unset KONG_ADMIN_LISTEN_SSL
fi



# set up the environment

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local

if [ -n "$HTTP_PROXY" -o -n "$HTTPS_PROXY" ]; then
  touch /etc/profile.d/proxy.sh
  touch /etc/apt/apt.conf.d/50proxy
fi

if [ -n "$HTTP_PROXY" ]; then
  printf "using http proxy: %s\n" $HTTP_PROXY

  echo "http_proxy=$HTTP_PROXY" >> /etc/profile.d/proxy.sh
  echo "HTTP_PROXY=$HTTP_PROXY" >> /etc/profile.d/proxy.sh
  echo "Acquire::http::proxy \"$HTTP_PROXY\";" >> /etc/apt/apt.conf.d/50proxy
  echo "http_proxy=$HTTP_PROXY" >> /etc/wgetrc
fi

if [ -n "$HTTPS_PROXY" ]; then
  printf "using https proxy: %s\n" $HTTPS_PROXY

  echo "https_proxy=$HTTPS_PROXY" >> /etc/profile.d/proxy.sh
  echo "HTTPS_PROXY=$HTTPS_PROXY" >> /etc/profile.d/proxy.sh
  echo "Acquire::https::proxy \"$HTTP_PROXY\";" >> /etc/apt/apt.conf.d/50proxy
  echo "https_proxy=$HTTPS_PROXY" >> /etc/wgetrc
fi


echo "*************************************************************************"
echo Setting up APT repositories
echo "*************************************************************************"

#postgres
sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"
wget --quiet -O - https://postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

#cassandra
if [ ! -f /etc/apt/sources.list.d/cassandra.sources.list ]; then
  echo 'deb http://debian.datastax.com/community stable main' | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
  wget -q -O - '$@' http://debian.datastax.com/debian/repo_key | sudo apt-key add -
fi

sudo apt-get update

echo "*************************************************************************"
echo Installing APT packages
echo "*************************************************************************"


#generic usability utilities
sudo apt-get install -y httpie jq

#Installing required dependencies
sudo apt-get install -y git curl make pkg-config unzip apt-transport-https language-pack-en


####################
echo "*************************************************************************"
echo Installing and configuring Postgres
echo "*************************************************************************"

set +o errexit
dpkg --list postgresql-$POSTGRES_VERSION > /dev/null 2>&1
if [ $? -ne 0 ]; then
sudo apt-get install -y postgresql-$POSTGRES_VERSION

# Configure Postgres
sudo sed -i "s/#listen_address.*/listen_addresses '*'/" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sudo bash -c "cat > /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf" << EOL
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               trust
EOL

sudo /etc/init.d/postgresql restart

# Create PG user and database
psql -U postgres <<EOF
\x
CREATE USER kong;
CREATE DATABASE kong OWNER kong;
CREATE DATABASE kong_tests OWNER kong;
EOF

fi
set -o errexit

#################
echo "*************************************************************************"
echo Installing Redis
echo "*************************************************************************"

sudo apt-get install -y redis-server
sudo chown vagrant /var/log/redis/redis-server.log

#####################
echo "*************************************************************************"
echo Installing Cassandra and java
echo "*************************************************************************"

#Install java runtime (Cassandra dependency)
set +o errexit
java -version  > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo Fetching and installing java...
  sudo mkdir -p /usr/lib/jvm
  sudo wget -q -O /tmp/jre-linux-x64.tar.gz --no-cookies --no-check-certificate --header 'Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jre-8u131-linux-x64.tar.gz
  sudo tar zxf /tmp/jre-linux-x64.tar.gz -C /usr/lib/jvm
  sudo update-alternatives --install '/usr/bin/java' 'java' '/usr/lib/jvm/jre1.8.0_131/bin/java' 1
  sudo update-alternatives --set java /usr/lib/jvm/jre1.8.0_131/bin/java
fi

#Install cassandra
dpkg --list cassandra > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo Fetching and installing Cassandra...
  sudo apt-get install cassandra=$CASSANDRA_VERSION -y --force-yes
  sudo /etc/init.d/cassandra restart
fi
set -o errexit
################
echo "*************************************************************************"
echo Fetching and installing Kong...
echo "*************************************************************************"

wget -q -O kong.deb "$KONG_DOWNLOAD_URL"

if [ $KONG_NUM_VERSION -lt 1000 ]; then
  #dnsmasq for Kong 0.9.x and earlier
  sudo apt-get install -y dnsmasq
fi

sudo dpkg -i kong.deb
rm kong.deb


###########################
# Install profiling tools #
###########################
if [ -n "$KONG_UTILITIES" ]; then
  # install tools
  echo "*************************************************************************"
  echo Installing systemtap, stapxx and openresty-systemtap-toolkit
  echo "*************************************************************************"

  # install systemtap
  # https://openresty.org/en/build-systemtap.html
  sudo apt-get install -y build-essential zlib1g-dev elfutils libdw-dev gettext
  wget -q http://sourceware.org/systemtap/ftp/releases/systemtap-3.0.tar.gz
  tar -xf systemtap-3.0.tar.gz
  cd systemtap-3.0/
  ./configure --prefix=/opt/stap --disable-docs \
              --disable-publican --disable-refdocs CFLAGS="-g -O2"
  make
  sudo make install
  rm -rf ./systemtap-3.0 systemtap-3.0.tar.gz

  # install stapxx and openresty-systemtap-toolkit
  pushd /usr/local
  git clone https://github.com/openresty/stapxx.git
  git clone https://github.com/openresty/openresty-systemtap-toolkit.git

  # install flamegraph
  git clone https://github.com/brendangregg/FlameGraph.git

  # install wrk and copy the binary to a location in PATH
  git clone https://github.com/wg/wrk.git
  cd wrk && make && sudo cp ./wrk /usr/local/bin/ && cd ..
  popd
fi


echo "*************************************************************************"
echo Update localization, paths, ulimit, etc
echo "*************************************************************************"

# Adjust PATH
export PATH=$PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx

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


# Adjust PATH for future ssh
echo "export PATH=\$PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin" >> /home/vagrant/.bashrc

# do the same for root so we access to profiling tools
echo "export PATH=\$PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin" >> /root/.bashrc

# copy host settings
if [ -n "$LOGLEVEL" ]; then
  echo "export KONG_LOG_LEVEL=$LOGLEVEL" >> /home/vagrant/.bashrc
fi
if [ -n "$ANREPORTS" ]; then
  echo "export KONG_ANONYMOUS_REPORTS=$ANREPORTS" >> /home/vagrant/.bashrc
fi

# create prefix (working directory) to the same location as source tree if available
if [ ! -d "/kong" ]; then
  sudo mkdir /kong
  sudo chown -R vagrant /kong
fi
echo "export KONG_PREFIX=/kong/servroot" >> /home/vagrant/.bashrc

# set admin listen addresses
echo "export KONG_ADMIN_LISTEN=\"$KONG_ADMIN_LISTEN\"" >> /home/vagrant/.bashrc
if [ -n "$KONG_ADMIN_LISTEN_SSL" ]; then
  echo "export KONG_ADMIN_LISTEN_SSL=$KONG_ADMIN_LISTEN_SSL" >> /home/vagrant/.bashrc
fi

# Adjust LUA_PATH to find the plugin dev setup
echo "export LUA_PATH=\"/kong-plugin/?.lua;/kong-plugin/?/init.lua;;\"" >> /home/vagrant/.bashrc

# Set locale
echo "export LC_ALL=en_US.UTF-8" >> /home/vagrant/.bashrc
echo "export LC_CTYPE=en_US.UTF-8" >> /home/vagrant/.bashrc
# fix locale warning
sudo echo "LC_CTYPE=\"en_US.UTF-8\"" >> /etc/default/locale
sudo echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local

echo .
echo "Successfully Installed Kong version: $KONG_VERSION"
