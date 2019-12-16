#!/usr/bin/env bash

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

export KONG_PLUGINS=cors,jwt,jwt-claims-headers,permission-middleware,rate-limiting

echo "******************************"
echo "Starting Kong"
echo "plugins enabled:"
echo $KONG_PLUGINS
echo "******************************"

if [ "$KONG_STATUS" == "running" ]; then
  kong restart
else
  kong start
fi

echo "******************************"
echo "Applying Kong Terraform config"
echo "******************************"

terraform apply -auto-approve
