#!/bin/bash

echo "***** Compiling kong middleware *****"

printf "\tpermission-middleware\n"
cd /kong-plugin/permission-middleware
luarocks make *.rockspec

printf "\tkong-spec-expose\n"
cd /kong-plugin/kong-spec-expose
lurarocks make *.rockspec

cd /

echo "***** Compiling kong *****"
make --directory=./kong dev

echo "***** installing terraform *****"
cd /tmp
wget --quiet https://releases.hashicorp.com/terraform/0.11.15-oci/terraform_0.11.15-oci_linux_amd64.zip
unzip -qq terraform_0.11.15-oci_linux_amd64.zip

mv ./terraform /usr/local/bin/
