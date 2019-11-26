#!/bin/bash
cd ../..

export KONG_PLUGINS=bundled,permission-middleware
echo "KONG PLUGINS MADE"

cd ./tf/dev
sudo terraform init

../../kong/bin/kong migrations bootstrap
kong start

terraform apply
