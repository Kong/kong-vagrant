# [Kong][website-url] :heavy_plus_sign: [Vagrant](https://www.vagrantup.com/)

[![Website][website-badge]][website-url]
[![Documentation][documentation-badge]][documentation-url]
[![Mailing List][mailing-list-badge]][mailing-list-url]
[![Gitter Badge][gitter-badge]][gitter-url]

[![][kong-logo]][website-url]

Vagrant is used to create an isolated environment for Kong 
including Postgres, Cassandra and Redis.

You can use the vagrant box either as an all-in-one Kong installation for
testing purposes, or you can link it up with source code and start developing
on Kong or on custom plugins.

## Testing Kong

If you just want to give Kong a test ride, and you have Vagrant installed, 
then you can simply clone this vagrant repo, and build the vm.

```shell
# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant

# build the machine
$ vagrant up

# start Kong, by ssh into the vm
$ vagrant ssh
$ kong start

# alternatively use ssh -c option to start Kong
$ vagrant ssh -c "kong start"
```

Kong is now started and is available on the default ports;

- `8000` proxy port
- `8443` ssl proxy port
- `8001` admin api
- `8444` ssl admin api

To verify Kong is running successfully, execute the following command (from
the host machine):

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

See the environments variables section below for defaults used and how to
modify the settings of the Vagrant machine. 

## Development environment

Once you have Vagrant installed, follow these steps to set up a development
environment for both Kong itself as well as for custum plugins. It will
install the development dependencies like the `busted` test framework.

```shell
# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant

# clone the Kong repo (inside the vagrant one)
$ git clone https://github.com/Mashape/kong

# only if you want to develop a custom plugin, also clone the plugin template
$ git clone https://github.com/Mashape/kong-plugin

# build a box with a folder synced to your local Kong and plugin sources
$ vagrant up

# ssh into the Vagrant machine, and setup the dev environment
$ vagrant ssh
$ cd /kong
$ make dev

# only if you want to run the custom plugin, tell Kong to load it
$ export KONG_CUSTOM_PLUGINS=myPlugin

# startup kong: while inside '/kong' call the start script from the repo!
$ cd /kong
$ bin/kong start
```

This will tell Vagrant to mount your local Kong repository under the guest's 
`/kong` folder, and (if you cloned it) the 'kong-plugin' repository under the
guest's `/kong-plugin` folder.

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
# 'catch-all' setup with the `uris` field set to '/'
# NOTE: for pre-0.10 versions 'uris=' below should be 'request_path='
$ curl -i -X POST \
  --url http://localhost:8001/apis/ \
  --data 'name=mockbin' \
  --data 'upstream_url=http://mockbin.org/request' \
  --data 'uris=/'

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

### Running Kong from the source repo

Because the start and stop scripts are in the repository, you must use those
to stop and start kong. Using the scripts that came with the base version you
specified when building the Vagrant box will lead to unpredictable results.

```shell
# ssh into the Vagrant machine
$ vagrant ssh

# only if you want to run the custom plugin, tell Kong to load it
$ export KONG_CUSTOM_PLUGINS=myPlugin

# startup kong: while inside '/kong' call the start script from the repo!
$ cd /kong
$ bin/kong start
```

### Testing Kong and custom plugins

To use the test helpers from the Kong repo, you must first setup the 
development environment as mentioned above.

To run test suites, you should first stop Kong, and clear any environment
variables you've set to prevent them from interfering with the tests.

The test environment has the same limitation as running from source in that it
must be executed from the Kong source repo at `/kong`, inside the Vagrant
machine.

```shell
# ssh into the Vagrant machine
$ vagrant ssh

# testing: while inside '/kong' call `busted` from the repo!
$ cd /kong
$ bin/busted

# or for more verbose output do
$ bin/busted -v -o gtest
```

Note that Kong comes with a special Busted script that runs against the
OpenResty environment, instead of regular busted which runs against Lua(JIT)
directly.

To test the plugin specific tests:
```shell
# ssh into the Vagrant machine
$ vagrant ssh

# testing: while inside '/kong' call `busted` from the repo, but specify
# the plugin testsuite to be executed
$ cd /kong
$ bin/busted /kong-plugin/spec
```

Eventually, to test Kong familiarize yourself with the 
[Makefile Operations](https://github.com/Mashape/kong#makefile).

### Development tips and tricks

- `export KONG_LUA_CODE_CACHE=false` turns the code caching off, you can start 
  Kong, edit your local files (on your host machine), and test your code without 
  restarting Kong.
- `export KONG_LOG_LEVEL=debug` to show detailed logs when coding
- `export KONG_PREFIX=/kong/servroot` will set the Kong working directory to 
  the same location where the tests run. It is in the Kong tree, excluded from the
  git repo, and accessible from the host to check logs when coding.

### Kong/OpenResty profiling

Vagrant can build the box with [systemtap](https://sourceware.org/systemtap/),
[stapxx](https://github.com/openresty/stapxx), and [openresty-systemtap-toolkit](https://github.com/openresty/openresty-systemtap-toolkit)
to aid in profiling Kong. See each project's Readme pages for usage details.

## Environment variables and configuration

You can alter the behavior of the provision step by setting the following 
environment variables:

| name            | description                                                               | default   |
| --------------- | ------------------------------------------------------------------------- | --------- |
| `KONG_VERSION`  | the Kong version number to download and install at the provision step     | `0.10.0`  |
| `KONG_VB_MEM`   | virtual machine memory (RAM) size *(in MB)*                               | `1024`    |
| `KONG_CASSANDRA`| the major Cassandra version to use, either `2` or `3`                     | `3`, or `2` for Kong versions `9.x` and older |
| `KONG_PATH`     | the path to mount your local Kong source under the guest's `/kong` folder | `./kong`, `../kong`, or nothing. In this order. |
| `KONG_PLUGIN_PATH` | the path to mount your local plugin source under the guest's `/kong-plugin` folder | `./kong-plugin`, `../kong-plugin`, or nothing. In this order. |
| `KONG_PROFILING` | boolean determining whether or not to build systemtap and friends tools   | undefined |

Use them when provisioning, e.g.:
```shell
$ KONG_VERSION=0.9.5 vagrant up
```

The `_PATH` variables are will take the value set, or the defaults, but the 
defaults will only be taken if they actually exist. As such the defaults allow
for 2 file structures, without any configuration.

Structure where everything resides inside the `kong-vagrant` repo:
```
-some_dir
  |-kong-vagrant
     |-kong
     |-kong-plugin
```

or if you prefer all repos on the same level:
```
-some_dir
  |-kong-vagrant
  |-kong
  |-kong-plugin
```


The (non-configurable) exposed ports are;

- `8000` proxy port
- `8443` ssl proxy port
- `8001` admin api
- `8444` ssl admin api

These are mapped 1-on-1 between the host and guest.

## Known Issues

### Incompatible versions error

When Kong starts it can give errors for incompatible versions. This happens for 
example when dependencies have been updated. Eg. 0.9.2 required Openresty 
1.9.15.1, whilst 0.9.5 requires 1.11.2.1. 

So please reprovision it and specify the proper version you want to work with 
(either newer or older, see the defaults above), as in the example below with 
version 0.9.2;

```shell
# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant/

# clone the Kong repo and switch explicitly to the 0.9.2 version.
# this will get the proper Kong source code for the version.
$ git clone https://github.com/Mashape/kong
$ cd kong
$ git checkout 0.9.2
$ cd ..

# start a box with a folder synced to your local Kong clone, and
# specifically targetting 0.9.2, to get the required binary versions
$ KONG_VERSION=0.9.2 vagrant up
```

### Vagrant error; The box 'hashicorp/precise64' could not be found

There is a known issue with Vagrant on OS X with an included `curl` version
that fails. See [stack overflow](http://stackoverflow.com/questions/40473943/vagrant-box-could-not-be-found-or-could-not-be-accessed-in-the-remote-catalog)
for a solution.

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
