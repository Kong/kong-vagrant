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
