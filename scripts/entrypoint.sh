#!/usr/bin/env bash

export KONG_PLUGINS=bundled,kong-spec-expose,permission-middleware

cd /tf/dev

sudo terraform init

kong migrations bootstrap

kong start

terraform apply -auto-approve
