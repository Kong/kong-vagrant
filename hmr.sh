#!usr/bin/env bash

reload_plugins() {
  echo "Reloading Kong Plugins"
  vagrant ssh -c "cd /kong-plugin; luarocks make permission-middleware*.rockspec"
  vagrant ssh -c "cd /tf/dev; terraform apply -auto-approve"
}

export -f reload_plugins

fswatch -0 -xr --event=Updated ../../permission-middleware | xargs -0 -n1 bash -c reload_plugins
