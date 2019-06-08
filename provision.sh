#!/bin/bash

set -o errexit

# Suppress some warnings
export DEBIAN_FRONTEND=noninteractive
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Parse and set up input parameters
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
   CASSANDRA_VERSION=2.2.13
   CASSANDRA_VERSION_REPO=22x
else
   CASSANDRA_VERSION=3.11.4
   CASSANDRA_VERSION_REPO=311x
fi

POSTGRES_VERSION=9.6

# Set some version dependent options
KONG_DOWNLOAD_URL="https://github.com/Kong/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.precise_all.deb"
KONG_ADMIN_LISTEN="0.0.0.0:8001"
KONG_ADMIN_LISTEN_SSL="0.0.0.0:8444"

if [ $KONG_NUM_VERSION -gt 001003 ]; then
  KONG_DOWNLOAD_URL="https://bintray.com/kong/kong-deb/download_file?file_path=kong-${KONG_VERSION}.trusty.all.deb"
fi

if [ $KONG_NUM_VERSION -ge 001300 ]; then
  # Kong 0.13.0 listen directives format changed, now combined
  KONG_ADMIN_LISTEN="0.0.0.0:8001, 0.0.0.0:8444 ssl"
  unset KONG_ADMIN_LISTEN_SSL
fi

if [ $KONG_NUM_VERSION -ge 001500 ]; then
  # use Bionic now instead of Trusty
  KONG_DOWNLOAD_URL="https://bintray.com/kong/kong-deb/download_file?file_path=kong-${KONG_VERSION}.bionic.all.deb"

  # Let's enable transparent listening option as well
  KONG_PROXY_LISTEN="0.0.0.0:8000 transparent, 0.0.0.0:8443 transparent ssl"

  # Kong 0.15.0 has a stream module, let's enable that too
  KONG_STREAM_LISTEN="0.0.0.0:9000 transparent"
fi

sudo chown -R vagrant /usr/local

if [ -n "$HTTP_PROXY" -o -n "$HTTPS_PROXY" ]; then
  touch /etc/profile.d/proxy.sh
  touch /etc/apt/apt.conf.d/50proxy
fi

if [ -n "$HTTP_PROXY" ]; then
  printf "Using HTTP Proxy: %s\n" $HTTP_PROXY

  echo "http_proxy=$HTTP_PROXY" >> /etc/profile.d/proxy.sh
  echo "HTTP_PROXY=$HTTP_PROXY" >> /etc/profile.d/proxy.sh
  echo "Acquire::http::proxy \"$HTTP_PROXY\";" >> /etc/apt/apt.conf.d/50proxy
  echo "http_proxy=$HTTP_PROXY" >> /etc/wgetrc
fi

if [ -n "$HTTPS_PROXY" ]; then
  printf "Using HTTPS Proxy: %s\n" $HTTPS_PROXY

  echo "https_proxy=$HTTPS_PROXY" >> /etc/profile.d/proxy.sh
  echo "HTTPS_PROXY=$HTTPS_PROXY" >> /etc/profile.d/proxy.sh
  echo "Acquire::https::proxy \"$HTTP_PROXY\";" >> /etc/apt/apt.conf.d/50proxy
  echo "https_proxy=$HTTPS_PROXY" >> /etc/wgetrc
fi

echo "*************************************************************************"
echo "Setting up APT repositories"
echo "*************************************************************************"

wget -q -O - '$@' https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo -E apt-key add -
sudo -E add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main"

wget -q -O - '$@' https://www.apache.org/dist/cassandra/KEYS | sudo -E apt-key add -
sudo -E add-apt-repository "deb http://www.apache.org/dist/cassandra/debian $CASSANDRA_VERSION_REPO main"

sudo -E apt-get update -qq
sudo -E apt-get upgrade -qq

echo "*************************************************************************"
echo "Installing APT packages"
echo "*************************************************************************"

if [ $KONG_NUM_VERSION -ge 001500 ]; then
  sudo -E apt-get install -qq iptables libcap2-bin nmap
fi

sudo -E apt-get install -qq httpie jq
sudo -E apt-get install -qq git curl make pkg-config unzip apt-transport-https language-pack-en libssl-dev m4 cpanminus

echo "*************************************************************************"
echo "Installing test tools for Test::Nginx"
echo "*************************************************************************"

cpanm -n -q Test::Nginx

echo "*************************************************************************"
echo "Installing and configuring Postgres $POSTGRES_VERSION"
echo "*************************************************************************"

set +o errexit
dpkg -f noninteractive --list postgresql-$POSTGRES_VERSION > /dev/null 2>&1
if [ $? -ne 0 ]; then
sudo -E apt-get install -qq postgresql-$POSTGRES_VERSION

# Configure Postgres
sudo sed -i "s/#listen_address.*/listen_addresses '*'/" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sudo bash -c "cat > /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf" << EOL
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               trust
EOL

sudo systemctl -q enable postgresql
sudo /etc/init.d/postgresql restart

# Create Postgres role and databases
psql -U postgres <<EOF
\x
CREATE ROLE kong;
ALTER ROLE kong WITH login;
CREATE DATABASE kong OWNER kong;
CREATE DATABASE kong_tests OWNER kong;
EOF

psql -d kong -U postgres <<EOF
\x
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA IF NOT EXISTS public AUTHORIZATION kong;
GRANT ALL ON SCHEMA public TO kong;
EOF

psql -d kong_tests -U postgres <<EOF
\x
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA IF NOT EXISTS public AUTHORIZATION kong;
GRANT ALL ON SCHEMA public TO kong;
EOF

fi
set -o errexit

echo "*************************************************************************"
echo "Installing Redis"
echo "*************************************************************************"

sudo -E apt-get install -qq redis-server
sudo chown vagrant /var/log/redis/redis-server.log

echo "*************************************************************************"
echo "Installing Cassandra $CASSANDRA_VERSION"
echo "*************************************************************************"

set +o errexit
dpkg -f noninteractive --list cassandra > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Installing Cassandra"
  sudo -E apt-get install -qq --allow-downgrades --allow-remove-essential --allow-change-held-packages cassandra=$CASSANDRA_VERSION
  sudo /etc/init.d/cassandra restart
fi

set -o errexit

echo "*************************************************************************"
echo "Fetching and installing Kong $KONG_VERSION"
echo "*************************************************************************"

echo $KONG_DOWNLOAD_URL

wget -q -O kong.deb "$KONG_DOWNLOAD_URL"

if [ $KONG_NUM_VERSION -lt 1000 ]; then
  sudo -E apt-get install -qq dnsmasq
fi

sudo -E dpkg -i kong.deb
rm kong.deb


if [ -n "$KONG_UTILITIES" ]; then
  echo "*************************************************************************"
  echo "Installing systemtap, stapxx, and openresty-systemtap-toolkit"
  echo "*************************************************************************"

  # Install systemtap: https://openresty.org/en/build-systemtap.html
  sudo -E apt-get install -qq build-essential zlib1g-dev elfutils libdw-dev gettext
  wget -q http://sourceware.org/systemtap/ftp/releases/systemtap-4.0.tar.gz
  tar -xf systemtap-4.0.tar.gz
  pushd systemtap-4.0/
    ./configure --prefix=/opt/stap --disable-docs \
                --disable-publican --disable-refdocs CFLAGS="-g -O2"
    make
    sudo make install
  popd
  rm -rf ./systemtap-4.0 systemtap-4.0.tar.gz

  # Install stapxx and openresty-systemtap-toolkit
  pushd /usr/local
  git clone https://github.com/openresty/stapxx.git
  git clone https://github.com/openresty/openresty-systemtap-toolkit.git

  # Install flamegraph
  git clone https://github.com/brendangregg/FlameGraph.git

  # Install wrk and copy the binary to a location in PATH
  git clone https://github.com/wg/wrk.git
  cd wrk && make && sudo cp ./wrk /usr/local/bin/ && cd ..
  popd
fi


echo "*************************************************************************"
echo "Update localization, paths, ulimit, etc."
echo "*************************************************************************"

echo 'alias ks="kong start -c kong.conf.default"' >> /home/vagrant/.bashrc
echo 'alias kmu="kong migrations up -c kong.conf.default"' >> /home/vagrant/.bashrc
echo 'alias kmr="kong migrations reset -c kong.conf.default --yes"' >> /home/vagrant/.bashrc
echo 'alias kss="kong stop ; ks"' >> /home/vagrant/.bashrc

export PATH=$PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx

# Prepare PATH to Lua libraries
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


# Adjust PATH for future SSH
echo "export PATH=/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin:/usr/local/openresty/luajit/bin:\$PATH:" >> /home/vagrant/.bashrc

# Do the same for root so we access to profiling tools
echo "export PATH=/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin:/usr/local/openresty/luajit/bin:\$PATH" >> /root/.bashrc

# Copy host settings
if [ -n "$LOGLEVEL" ]; then
  echo "export KONG_LOG_LEVEL=$LOGLEVEL" >> /home/vagrant/.bashrc
fi
if [ -n "$ANREPORTS" ]; then
  echo "export KONG_ANONYMOUS_REPORTS=$ANREPORTS" >> /home/vagrant/.bashrc
fi

# Create prefix (working directory) to the same location as source tree if available
if [ ! -d "/kong" ]; then
  sudo mkdir /kong
  sudo chown -R vagrant /kong
fi
echo "export KONG_PREFIX=/kong/servroot" >> /home/vagrant/.bashrc

# Set admin listen addresses
echo "export KONG_ADMIN_LISTEN=\"$KONG_ADMIN_LISTEN\"" >> /home/vagrant/.bashrc
if [ -n "$KONG_ADMIN_LISTEN_SSL" ]; then
  echo "export KONG_ADMIN_LISTEN_SSL=\"$KONG_ADMIN_LISTEN_SSL\"" >> /home/vagrant/.bashrc
fi

# Set stream and proxy listen addresses for Kong > 0.15.0
if [ $KONG_NUM_VERSION -ge 001500 ]; then
  echo "export KONG_PROXY_LISTEN=\"$KONG_PROXY_LISTEN\"" >> /home/vagrant/.bashrc
  echo "export KONG_STREAM_LISTEN=\"$KONG_STREAM_LISTEN\"" >> /home/vagrant/.bashrc
fi

# Adjust LUA_PATH to find the source and plugin dev setup
echo "export LUA_PATH=\"/kong/?.lua;/kong/?/init.lua;/kong-plugin/?.lua;/kong-plugin/?/init.lua;;\"" >> /home/vagrant/.bashrc
echo "if [ \$((1 + RANDOM % 20)) -eq 1 ]; then kong roar; fi" >> /home/vagrant/.bashrc

# Set Test::Nginx variables since it cannot have sockets on a mounted drive
echo "export TEST_NGINX_NXSOCK=/tmp" >> /home/vagrant/.bashrc

# Set locale
echo "export LC_ALL=en_US.UTF-8" >> /home/vagrant/.bashrc
echo "export LC_CTYPE=en_US.UTF-8" >> /home/vagrant/.bashrc

# Fix locale warning
sudo echo "LC_CTYPE=\"en_US.UTF-8\"" >> /etc/default/locale
sudo echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale

# Assign permissions to "vagrant" user
sudo chown -R vagrant /usr/local

if [ $KONG_NUM_VERSION -ge 001500 ]; then
  # Allow non-root to start Kong with transparent flag
  sudo setcap cap_net_admin=eip /usr/local/openresty/nginx/sbin/nginx
fi

echo .
echo "Successfully Installed Kong version: $KONG_VERSION"
