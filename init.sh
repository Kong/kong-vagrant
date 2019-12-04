#!/bin/bash

cd /kong-plugin

echo "***** Compiling kong middleware *****"
printf "\tpermission-middleware\n"
luarocks make permission-middleware*.rockspec

cd /

echo "***** Compiling kong *****"
make --directory=./kong dev
