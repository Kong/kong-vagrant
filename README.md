# [Kong][website-url] :heavy_plus_sign: [Vagrant](https://www.vagrantup.com/)

[![Website][website-badge]][website-url]
[![Documentation][documentation-badge]][documentation-url]
[![Mailing List][mailing-list-badge]][mailing-list-url]
[![Gitter Badge][gitter-badge]][gitter-url]

[![][kong-logo]][website-url]

Vagrant is used to create an isolated development environment for Kong 
including Postgres, Cassandra and Redis.

## Starting the environment

Once you have Vagrant installed, follow those steps:

```shell
# clone the Kong repo and switch to the next branch to use the latest, unrelease code
$ git clone https://github.com/Mashape/kong
$ cd kong
$ git checkout next
$ cd ..

# clone the Kong Plugin repo required to run the Vagrant box
$ git clone https://github.com/Mashape/kong-plugin

# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant/

# start a box with a folder synced to your local Kong clone
$ vagrant up
```

This will tell Vagrant to mount your local Kong repository under the guest's 
`/kong` folder.

The startup process will install all the dependencies necessary for developing 
(including Postgres, Cassandra and Redis). The Kong source code is mounted at 
`/kong`. The host ports `8000`, `8001` and `8443` will be forwarded to the 
Vagrant box.

### Environment Variables

You can alter the behavior of the provision step by setting the following 
environment variables:

| name            | description                                                               | default   |
| --------------- | ------------------------------------------------------------------------- | --------- |
| `KONG_PATH`     | the path to mount your local Kong source under the guest's `/kong` folder | `../kong` |
| `KONG_VERSION`  | the Kong version number to download and install at the provision step     | `0.9.9`   |
| `KONG_VB_MEM`   | virtual machine memory (RAM) size *(in MB)*                               | `1024`    |
| `KONG_PLUGIN_PATH` | the path to mount your local plugin source under the guest's `/plugin` folder | `../kong-plugin` |

Use them when provisioning, e.g.:
```shell
$ KONG_VERSION=0.9.5 KONG_VB_MEM=2048 vagrant up
```

## Building and running Kong

To build Kong execute the following commands:

```shell
# SSH into the vagrant box
$ vagrant ssh

# switch to the mounted Kong repo
$ cd /kong

# install Kong
$ make dev

# start Kong
$ bin/kong start
```

## Testing Kong

To verify Kong is running successfully, execute the following command from the 
host machine:

```shell
$ curl http://localhost:8001
```

You should receive a JSON response:

```javascript
{
  "tagline": "Welcome to Kong",
  "version": "x.x.x",
  "hostname": "precise64",
  "lua_version": "LuaJIT 2.1.0-alpha",
  "plugins": {
    "enabled_in_cluster": {},
    "available_on_server": [
      ...
    ]
  }
}
```

## Developing plugins

Clone the plugin template next to your clones of `kong` and `kong-vagrant`:

```shell
# clone the plugin template repository
$ git clone https://github.com/Mashape/kong-plugin
```

Setup Kong to use the plugin:
```shell
# SSH into the vagrant box
$ vagrant ssh

# tell Kong to load the custom plugin
$ export KONG_CUSTOM_PLUGINS=myPlugin

# start Kong
$ cd /kong
$ bin/kong start
```

To verify Kong has loaded the plugin successfully, execute the following command 
from the host machine:

```shell
$ curl http://localhost:8001
```
In the response you get, the plugins list should now contain an entry "myPlugin"
to indicate the plugin was loaded.

To start using the plugin, execute from the host:
```shell
# create an api that simply echoes the request using mockbin, using a 
# 'catch-all' setup with the request path set to '/'
$ curl -i -X POST \
  --url http://localhost:8001/apis/ \
  --data 'name=mockbin' \
  --data 'upstream_url=http://mockbin.org/request' \
  --data 'request_path=/'

# add the custom plugin, to our new api
$ curl -i -X POST \
  --url http://localhost:8001/apis/mockbin/plugins/ \
  --data 'name=myPlugin'
```

Check whether it is working by making a request from the host:
```shell
$ curl -i http://localhost:8000
```
The response you get should be an echo (by Mockbin) of the request. But in the
response headers the plugin has now inserted a header `Bye-World`.

## Testing plugins

The plugin tests can use the helpers that come with the Kong repo for testing.
To execute the basic tests that come with the plugin execute:

```shell
# SSH into the vagrant box
$ vagrant ssh

#enter the Kong repo
cd /kong

# if not done so already make a dev environment
$ make dev

# run the plugin tests from the Kong repo
$ bin/busted /plugin/spec

# for more verbose output do
$ bin/busted -v -o gtest /plugin/spec
```


## Coding

- `export KONG_LUA_CODE_CACHE=false` turns the code caching off, you can start 
  Kong, edit your local files (on your host machine), and test your code without 
  restarting Kong.
- `export KONG_LOG_LEVEL=debug` to show detailed logs when coding
- `export KONG_PREFIX=/kong/servroot` will set the Kong working directory to 
  the same location where the tests run. It is in the Kong tree, excluded from the
  git repo, and accessible from the host to check logs when coding.

## Testing

- run the tests from the vagrant box. Not from the host.
- stop Kong before running the tests
- clear any environment variables set before testing
- `cd /kong && bin/busted` to run the tests. Check busted documentation for
  additional commandline options.

Eventually, to test Kong familiarize yourself with the 
[Makefile Operations](https://github.com/Mashape/kong#makefile).

## Known Issues

### DNS failure

If for some reason the Vagrant box doesn't resolve properly DNS names, please 
execute the following comand on the host:

```
$ vagrant halt
$ VBoxManage modifyvm "vagrant_kong" --natdnsproxy1 on
```

and then re-provision the image by running:

```
$ vagrant up --provision
```

### Incompatible versions error

When Kong starts it can give errors for incompatible versions. This happens for 
example when depedencies have been updated. Eg. 0.9.2 required Openresty 
1.9.15.1, whilst 0.9.5 requires 1.11.2.1. 

So please reprovision it and specify the proper version you want to work with 
(either newer or older, see the defaults above), as in the example below with 
version 0.9.2;

```shell
# clone the Kong repo and switch explicitly to the 0.9.2 version.
# this will get the proper Kong source code for the version.
$ git clone https://github.com/Mashape/kong
$ cd kong
$ git checkout 0.9.2

# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant/

# start a box with a folder synced to your local Kong clone, and
# specifically targetting 0.9.2, to get the required binary versions
$ KONG_VERSION=0.9.2 vagrant up
```

## Enterprise Support

Support, Demo, Training, API Certifications and Consulting available at http://getkong.org/enterprise.

[kong-logo]: http://i.imgur.com/4jyQQAZ.png
[website-url]: https://getkong.org/
[website-badge]: https://img.shields.io/badge/GETKong.org-Learn%20More-43bf58.svg
[documentation-url]: https://getkong.org/docs/
[documentation-badge]: https://img.shields.io/badge/Documentation-Read%20Online-green.svg
[gitter-url]: https://gitter.im/Mashape/kong
[gitter-badge]: https://img.shields.io/badge/Gitter-Join%20Chat-blue.svg
[mailing-list-badge]: https://img.shields.io/badge/Email-Join%20Mailing%20List-blue.svg
[mailing-list-url]: https://groups.google.com/forum/#!forum/konglayer
