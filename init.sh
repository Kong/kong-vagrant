#!/bin/bash

echo "***** Compiling kong middleware *****"

printf "\tpermission-middleware\n"
cd /kong-plugin/permission-middleware
luarocks make *.rockspec

printf "\tkong-spec-expose\n"
cd /kong-plugin/kong-spec-expose
lurarocks make *.rockspec

echo "***** Compiling kong *****"

cd /
make --directory=./kong dev

echo "***** installing terraform *****"

cd /tmp
wget --quiet https://releases.hashicorp.com/terraform/0.12.17/terraform_0.12.17_linux_amd64.zip
unzip -qq terraform*.zip
mv ./terraform /usr/local/bin/
