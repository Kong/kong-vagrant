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

# TF_VAR_sb_api_permissions_host=10.90.41.171 TF_VAR_sb_api_permissions_port=3011 TF_VAR_sb_api_resources_host=10.90.41.171 TF_VAR_sb_api_resources_port=3010
# KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware TF_VAR_sb_api_permissions_host=10.90.41.171 TF_VAR_sb_api_permissions_port=3011 TF_VAR_sb_api_resources_host=10.90.41.171 TF_VAR_sb_api_resources_port=3010 terraform apply -auto-approve
