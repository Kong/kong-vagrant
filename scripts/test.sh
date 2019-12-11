#!/usr/bin/env bash

export PATH=/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin:/usr/local/openresty/luajit/bin:$PATH:

/kong/bin/busted /kong-plugin
