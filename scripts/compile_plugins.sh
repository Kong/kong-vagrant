#!/usr/bin/env bash

cd /kong-plugin

for i in *; do
  if [ -d $i ]; then
    cd $i

    printf "\t$i\n\n"

    luarocks make *.rockspec

    cd /kong-plugin
  fi
done
