#!/bin/bash

cd /kong-plugin

luarocks make permission-middleware-0.1-1.rockspec
echo "***** PLUGINS MADE *****"

cd /

make --directory=./kong dev

# Install terraform
sudo snap install terraform

sudo mkdir -p ./home/vagrant/.terraform.d/plugins/

sudo mv ./home/vagrant/terraform-provider-kong_v5.0.0 ./home/vagrant/.terraform.d/plugins/

