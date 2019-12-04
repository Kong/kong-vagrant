#!/bin/bash

cd /kong-plugin
luarocks make permission-middleware-0.1-1.rockspec
cd /

echo "PLUGINS MADE"

make --directory=./kong dev

# Install terraform
sudo apt-get install unzip
wget --quiet https://releases.hashicorp.com/terraform/0.11.15-oci/terraform_0.11.15-oci_linux_amd64.zip
unzip -qq terraform_0.11.15-oci_linux_amd64.zip

sudo mv ./terraform /usr/local/bin/
sudo rm ./terraform_0.11.15-oci_linux_amd64.zip
sudo mkdir -p ./home/vagrant/.terraform.d/plugins/

sudo mv ./home/vagrant/terraform-provider-kong_v5.0.0 ./home/vagrant/.terraform.d/plugins/terraform-provider-kong_v5.0.0
