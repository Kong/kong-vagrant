#!/usr/bin/env bash

export KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware

cd /tf/dev

terraform init

kong migrations bootstrap

KONG_STATUS="$(kong health | grep running -o)"

if [ "$KONG_STATUS" == "running" ]; then
  kong restart
else
  kong start
fi

terraform apply -auto-approve
