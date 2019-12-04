#!/bin/env bash

export KONG_PLUGINS=bundled,permission-middleware

cd /tf/dev

sudo terraform init

kong migrations bootstrap

kong start

terraform apply -auto-approve
