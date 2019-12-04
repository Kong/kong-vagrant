#!/bin/bash

printf "***** Compiling kong middleware *****\n\n"

cd /kong-plugin

for i in *; do
  if [ -d $i ]; then
    cd $i

    printf "\t$i\n\n"

    luarocks make *.rockspec

    cd /kong-plugin
  fi
done

printf "***** Compiling kong *****\n\n"

cd /
make --directory=./kong dev

printf "***** installing terraform *****\n\n"

cd /tmp
wget --quiet https://releases.hashicorp.com/terraform/0.12.17/terraform_0.12.17_linux_amd64.zip
unzip -qq terraform*.zip
mv ./terraform /usr/local/bin/
