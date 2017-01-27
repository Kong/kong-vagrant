# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.4.3"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if ENV["KONG_PATH"]
    source = ENV["KONG_PATH"]
  else
    source = "../kong"
  end

  if ENV['KONG_VB_MEM']
    memory = ENV["KONG_VB_MEM"]
  else
    memory = 512
  end

  if ENV["KONG_VERSION"]
    version = ENV["KONG_VERSION"]
  else
    version = "0.9.7"
  end

  config.vm.provider :virtualbox do |vb|
   vb.name = "vagrant_kong"
   vb.memory = memory
  end

  config.vm.box = "hashicorp/precise64"

  config.vm.synced_folder source, "/kong"

  config.vm.network :forwarded_port, guest: 8000, host: 8000
  config.vm.network :forwarded_port, guest: 8001, host: 8001
  config.vm.network :forwarded_port, guest: 8443, host: 8443

  config.vm.provision "shell", path: "provision.sh", :args => version
end
