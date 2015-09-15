# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.4.3"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider :virtualbox do |vb|
   vb.name = "vagrant_kong"
   vb.memory = ENV['KONG_VB_MEM'] || 2048
  end

  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  if ENV["KONG_PATH"]
    source = ENV["KONG_PATH"]
  else
    source = "../kong"
  end

  config.vm.synced_folder source, "/kong"

  config.vm.network :forwarded_port, guest: 8000, host: 8000
  config.vm.network :forwarded_port, guest: 8001, host: 8001

  config.vm.provision "shell", inline: "
    CASSANDRA_VERSION=2.1.8

    # Install Oracle Java
    sudo mkdir -p /usr/lib/jvm
    sudo wget -q -O /tmp/jre-linux-x64.tar.gz --no-cookies --no-check-certificate --header 'Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie' http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jre-8u60-linux-x64.tar.gz
    sudo tar zxvf /tmp/jre-linux-x64.tar.gz -C /usr/lib/jvm
    sudo update-alternatives --install '/usr/bin/java' 'java' '/usr/lib/jvm/jre1.8.0_60/bin/java' 1
    sudo update-alternatives --set java /usr/lib/jvm/jre1.8.0_60/bin/java

    # Install Cassandra
    echo 'deb http://debian.datastax.com/community stable main' | tee -a /etc/apt/sources.list.d/cassandra.sources.list
    wget -q -O - '$@' http://debian.datastax.com/debian/repo_key | apt-key add -

    sudo apt-get update
    sudo apt-get install git curl make unzip netcat lua5.1 openssl libpcre3 dnsmasq cassandra=$CASSANDRA_VERSION -y --force-yes

    echo 'nameserver 10.0.2.3' >> /etc/resolv.conf
    /etc/init.d/cassandra restart

    # Install latest Kong
    TMP=/tmp/build/tmp
    rm -rf $TMP
    mkdir -p $TMP
    cd $TMP
    wget -q http://downloadkong.org/precise_all.deb
    dpkg -i precise_all.deb
  "
end
