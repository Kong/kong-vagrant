#!/usr/bin/env bash

export KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware

cd /tf/dev

terraform init

sudo -u vagrant kong migrations bootstrap

KONG_STATUS="$(kong health | grep running -o)"

if [ "$KONG_STATUS" == "running" ]; then
  sudo -u vagrant kong restart
else
  sudo -u vagrant kong start
fi

terraform apply -auto-approve
