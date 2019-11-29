#!usr/bin/env bash

reload_plugins () {
  echo "Reloading Kong Plugins"
  vagrant ssh -c "cd /kong-plugin; luarocks make permission-middleware-0.1-1.rockspec"
  vagrant ssh -c "cd /tf/dev; echo "yes" | terraform apply"
}

export -f reload_plugins

fswatch -0 -xr --event=Updated ../../permission-middleware | xargs -0 -n1 bash -c reload_plugins



