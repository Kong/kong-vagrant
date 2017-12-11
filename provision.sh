#!/bin/bash

set -o errexit

KONG_VERSION=$1
CASSANDRA_VERSION=$2
KONG_PROFILING=$3
ANREPORTS=$4
LOGLEVEL=$5

if [ "$CASSANDRA_VERSION" = "2" ]; then
   CASSANDRA_VERSION=2.2.8
else
   CASSANDRA_VERSION=3.0.9
fi

echo "Installing Kong version: $KONG_VERSION"

# Installing other dependencies
sudo apt-get update
sudo apt-get install -y git curl make pkg-config unzip libpcre3-dev apt-transport-https language-pack-en

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
sudo apt-get install -y redis-server
sudo chown vagrant /var/log/redis/redis-server.log

#####################
# install Cassandra #
######################
# Install java runtime (Cassandra dependency)
echo Fetching and installing java...
sudo mkdir -p /usr/lib/jvm
sudo wget -q -O /tmp/jre-linux-x64.tar.gz --no-cookies --no-check-certificate --header 'Cookie: oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jre-8u131-linux-x64.tar.gz
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
set +o errexit
wget -q -O kong.deb "https://bintray.com/kong/kong-community-edition-deb/download_file?file_path=dists%2Fkong-community-edition-${KONG_VERSION}.trusty.all.deb"
if [ ! $? -eq 0 ]
then
  # 0.10.3 and earlier are on Github
  echo "failed downloading from BinTray, trying Github..."
  set -o errexit
  wget -q -O kong.deb https://github.com/Kong/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.precise_all.deb
fi
set -o errexit


sudo apt-get update
sudo apt-get install -y netcat openssl libpcre3 dnsmasq procps perl
sudo dpkg -i kong.deb
rm kong.deb


###########################
# Install profiling tools #
###########################
if [ -n "$KONG_PROFILING" ]; then
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


#############
# Finish... #
#############

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

# set prefix (working directory) to the source tree if available (same as Kong test suite)
if [ -d "/kong" ]; then
  echo "export KONG_PREFIX=/kong/servroot" >> /home/vagrant/.bashrc
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

echo "Successfully Installed Kong version: $KONG_VERSION"
