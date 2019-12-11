#!/bin/bash

echo "*************************************"
echo "Compiling kong middleware"
echo "*************************************"

cd /kong-plugin

for i in *; do
  if [ -d $i ]; then
    cd $i

    printf "\t$i\n\n"

    luarocks make *.rockspec

    cd /kong-plugin
  fi
done

echo "*************************************"
echo "Compiling kong"
echo "*************************************"

cd /
make --directory=./kong dev

if [ ! -f /usr/local/bin/terraform ] ; then
  echo "*************************************"
  echo "Installing terraform"
  echo "*************************************"

  cd /tmp
  wget --quiet https://releases.hashicorp.com/terraform/0.12.17/terraform_0.12.17_linux_amd64.zip
  unzip -qq terraform*.zip
  mv ./terraform /usr/local/bin/
fi
