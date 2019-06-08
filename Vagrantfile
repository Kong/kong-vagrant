# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.4.3"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if ENV["KONG_PATH"]
    source = ENV["KONG_PATH"]
  elsif File.directory?("./kong")
    source = "./kong"
  elsif File.directory?("../kong")
    source = "../kong"
  else
    source = ""
  end

  if ENV["KONG_PLUGIN_PATH"]
    plugin_source = ENV["KONG_PLUGIN_PATH"]
  elsif File.directory?("./kong-plugin")
    plugin_source = "./kong-plugin"
  elsif File.directory?("../kong-plugin")
    plugin_source = "../kong-plugin"
  else
    plugin_source = ""
  end

  if ENV['KONG_VB_MEM']
    memory = ENV["KONG_VB_MEM"]
  else
    memory = 4096
  end

  if ENV["KONG_NGINX_WORKER_PROCESSES"]
    cpus = ENV["KONG_NGINX_WORKER_PROCESSES"]
  else
    cpus = 2
  end

  if ENV["KONG_VERSION"]
    version = ENV["KONG_VERSION"]
  else
    version = "1.2.0"
  end

  if ENV["KONG_CASSANDRA"]
    cversion = ENV["KONG_CASSANDRA"]
    if not cversion == "2"
      if not cversion == "3"
        raise "KONG_CASSANDRA must be either 2 or 3"
      end
    end
  else
    # set a default, 3.x, or for Kong < 0.10 then 2.x
    cversion = "3"
    v = version.split('.')
    if v[0].strip.to_i == 0
      if v[1].strip.to_i < 10
        cversion = "2"
      end
    end
  end

  if ENV["KONG_UTILITIES"]
    utils = "1"
  else
    utils = ""
  end

  if ENV["KONG_ANONYMOUS_REPORTS"]
    anreports = ENV["KONG_ANONYMOUS_REPORTS"]
  else
    anreports = ""
  end

  if ENV["KONG_LOG_LEVEL"]
    loglevel = ENV["KONG_LOG_LEVEL"]
  else
    loglevel = ""
  end

  config.vm.provider :virtualbox do |vb|
    vb.name = "vagrant_kong"
    vb.memory = memory
    vb.cpus = cpus
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/ — timesync-set-threshold", 10000]
  end

  config.vm.box = "ubuntu/bionic64"

  if not source == ""
    config.vm.synced_folder source, "/kong"
  end
  if not plugin_source == ""
    config.vm.synced_folder plugin_source, "/kong-plugin"
  end

  config.vm.network :forwarded_port, guest: 8000, host: 8000
  config.vm.network :forwarded_port, guest: 8001, host: 8001
  config.vm.network :forwarded_port, guest: 8443, host: 8443
  config.vm.network :forwarded_port, guest: 8444, host: 8444
  config.vm.network :forwarded_port, guest: 9000, host: 9000 # only used with TCP stream proxy with Kong >= 0.15.0
  config.vm.network :forwarded_port, guest: 5432, host: 65432

  config.vm.provision "shell", path: "provision.sh",
     env: { "HTTP_PROXY": ENV["HTTP_PROXY"], "HTTPS_PROXY": ENV["HTTPS_PROXY"]},
    :args => [version, cversion, utils, anreports, loglevel]
end
