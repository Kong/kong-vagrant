#!/usr/bin/env bash

export KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware

echo "******************************"
echo "Initializing Terraform"
echo "******************************"

cd /tf/dev

terraform init

echo "******************************"
echo "Bootstrapping Kong DB"
echo "******************************"

kong migrations bootstrap

KONG_STATUS="$(kong health | grep running -o)"

echo "******************************"
echo "Starting Kong"
echo "plugins enabled:"
echo $KONG_PLUGINS
echo "******************************"

if [ "$KONG_STATUS" == "running" ]; then
  KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware kong restart
else
  KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware kong start
fi

echo "******************************"
echo "Applying Kong Terraform config"
echo "******************************"

terraform apply -auto-approve
