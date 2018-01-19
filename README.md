# [Kong][website-url] :heavy_plus_sign: [Vagrant](https://www.vagrantup.com/)

[![Website][website-badge]][website-url]
[![Documentation][documentation-badge]][documentation-url]
[![Mailing List][mailing-list-badge]][mailing-list-url]
[![Gitter Badge][gitter-badge]][gitter-url]

[![][kong-logo]][website-url]

Vagrant is used to create an isolated environment for Kong
including PostgreSQL, Cassandra, and Redis.

You can use the vagrant box either as an all-in-one Kong installation for
testing purposes, or you can link it up with source code and start developing
on Kong or on custom plugins.

# Table of contents

* [Testing Kong](#testing-kong)
* [Development environment](#development-environment)
  * [Running Kong from the source repo](#running-kong-from-the-source-repo)
  * [Testing Kong and custom plugins](#testing-kong-and-custom-plugins)
  * [Development tips and tricks](#development-tips-and-tricks)
  * [Kong/OpenResty profiling](#kongopenresty-profiling)
* [Environment variables and configuration](#environment-variables-and-configuration)
* [Known issues](#known-issues)
* [Enterprise support](#enterprise-support)

**IMPORTANT**: The Kong admin api is by default only available on localhost,
but to be able to access it from the host system, the Vagrant box will listen
on all interfaces by default. This might be a security risk in your environment.

## Testing Kong

If you just want to give Kong a test ride, and you have Vagrant installed,
then you can simply clone this vagrant repo, and build the VM.

```shell
# clone this repository
$ git clone https://github.com/Kong/kong-vagrant
$ cd kong-vagrant

# build the machine
$ vagrant up

# start Kong, by ssh into the vm
$ vagrant ssh
$ kong start --run-migrations

# alternatively use ssh -c option to start Kong
$ vagrant ssh -c "kong start --run-migrations"
```

Kong is now started and is available on the default ports;

- `8000` Proxy port
- `8443` SSL Proxy port
- `8001` Admin API
- `8444` SSL Admin API

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


See the [environment variables section](#environment-variables-and-configuration)
below for defaults used and how to modify the settings of the Vagrant machine.

## Development environment

Once you have Vagrant installed, follow these steps to set up a development
environment for both Kong itself as well as for custom plugins. It will
install the development dependencies like the `busted` test framework.

```shell
# clone this repository
$ git clone https://github.com/Kong/kong-vagrant
$ cd kong-vagrant

# clone the Kong repo (inside the vagrant one)
$ git clone https://github.com/Kong/kong

# only if you want to develop a custom plugin, also clone the plugin template
$ git clone https://github.com/Kong/kong-plugin

# build a box with a folder synced to your local Kong and plugin sources
$ vagrant up

# ssh into the Vagrant machine, and setup the dev environment
$ vagrant ssh
$ cd /kong
$ make dev

# only if you want to run the custom plugin, tell Kong to load it
$ export KONG_CUSTOM_PLUGINS=myplugin

# startup kong: while inside '/kong' call `kong` from the repo as `bin/kong`!
# we will also need to ensure that migrations are up to date
$ cd /kong
$ bin/kong migrations up
$ bin/kong start
```

This will tell Vagrant to mount your local Kong repository under the guest's
`/kong` folder, and (if you cloned it) the 'kong-plugin' repository under the
guest's `/kong-plugin` folder.

To verify Kong has loaded the plugin successfully, execute the following
command from the host machine:

```shell
$ curl http://localhost:8001
```
In the response you get, the plugins list should now contain an entry
"myplugin" to indicate the plugin was loaded.

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
  --data 'name=myplugin'
```

Check whether it is working by making a request from the host:
```shell
$ curl -i http://localhost:8000
```
The response you get should be an echo (by Mockbin) of the request. But in the
response headers the plugin has now inserted a header `Bye-World`.

### Running Kong from the source repo

Because the start and stop scripts are in the repository, you must use those
to stop and start Kong. Using the scripts that came with the base version you
specified when building the Vagrant box will lead to unpredictable results.

```shell
# ssh into the Vagrant machine
$ vagrant ssh

# only if you want to run the custom plugin, tell Kong to load it
$ export KONG_CUSTOM_PLUGINS=myplugin

# startup kong: while inside '/kong' call `kong` from the repo as `bin/kong`!
# we will also need to ensure that migrations are up to date
$ cd /kong
$ bin/kong migrations up
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

# testing: while inside '/kong' call `busted` from the repo as `bin/busted`!
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

# testing: while inside '/kong' call `busted` from the repo as `bin/busted`,
# but specify the plugin testsuite to be executed
$ cd /kong
$ bin/busted /kong-plugin/spec
```

To log stuff for debugging during your tests, you need to realize that there
are generally 2 processes running when testing:

1. Test files executed by `busted` that run your tests
2. The Kong instance that your tests are running against.

So to debug you can simply use the `print` function. In the former case the
output will be in your terminal from where you executed the tests. In the
latter case the output will be in the `error.log` file, but this file is
cleaned automatically in between tests.
Because the Kong tests run in the `servroot` prefix inside the Kong repo
you can track them using a `tail` command, see [Log files](#log-files).

## Log files

Inside the virtual machine, the Kong prefix (working directory) will be set to
`/kong/servroot`.

You can track the log files (from the host) like this for example:

```shell
vagrant ssh -c "tail -F /kong/servroot/logs/error.log"
```

If you have the Kong source tree available, then `/kong` will be mounted
from the host and the prefix will be on the host in `<kong-repo>/servroot` (the
same location where the tests will also run).
In this case you can track the log files directly on the host like this for example:

```shell
tail -F <kong-repo>/servroot/logs/error.log"
```

### Development tips and tricks

- Add `export KONG_LOG_LEVEL=debug` to your bash profile on the host so it will be
  automatically set whenever you rebuild the VM (applies to other environment
  variables as well)
- To run individual tests use the `--tags` switch in busted. Define a test with a tag;
  ```lua
  it("will test something #only", function()
    -- test here
  end
  ```
  Then execute the test with `bin/busted --tags=only`
- Some snippets for debug statements on [Kong nation](https://discuss.konghq.com/t/best-practices-for-kong-debugging-example/182/3).

### Kong/OpenResty profiling

Vagrant can build the box with [systemtap](https://sourceware.org/systemtap/),
[stapxx](https://github.com/openresty/stapxx), and [openresty-systemtap-toolkit](https://github.com/openresty/openresty-systemtap-toolkit)
to aid in profiling Kong. See each project's Readme pages for usage details.
To enable those tools use `KONG_PROFILING=true` when building the VM.

## Environment variables and configuration

These environment variables are copied from the Host system into the virtual
machine upon provisioning:

| name            | description                                                                           |
| --------------- | ------------------------------------------------------------------------------------- |
| `KONG_LOG_LEVEL`  | setting the `KONG_LOG_LEVEL` variable in the virtual machine |
| `HTTP_PROXY` & `HTTPS_PROXY` | Proxy settings to be able to properly build the machine when using a proxy |

You can alter the behavior of the provision step by setting the following
environment variables:

| name            | description                                                               | default   |
| --------------- | ------------------------------------------------------------------------- | --------- |
| `KONG_VERSION`  | the Kong version number to download and install at the provision step     | `0.12.1`  |
| `KONG_VB_MEM`   | virtual machine memory (RAM) size *(in MB)*                               | `4096`    |
| `KONG_CASSANDRA`| the major Cassandra version to use, either `2` or `3`                     | `3`, or `2` for Kong versions `9.x` and older |
| `KONG_PATH`     | the path to mount your local Kong source under the guest's `/kong` folder | `./kong`, `../kong`, or nothing. In this order. |
| `KONG_PLUGIN_PATH` | the path to mount your local plugin source under the guest's `/kong-plugin` folder | `./kong-plugin`, `../kong-plugin`, or nothing. In this order. |
| `KONG_PROFILING` | boolean determining whether or not to build systemtap and friends tools   | undefined |
| `KONG_NGINX_WORKER_PROCESSES`  | the number of CPUs available to the virtual machine (relates to the number of nginx workers) | `2` |

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

- `8000` Proxy port
- `8443` SSL Proxy port
- `8001` Admin API
- `8444` SSL Admin API

These are mapped 1-on-1 between the host and guest.

## Known issues

### worker_connections are not enough error

When running tests these errors occasionally happen. The underlying reason seems
to be that in the VM the connections are not freed up quickly enough. There
seem to be 2 workarounds;

- add more memory to the VM. Recreate the vm with:
```
KONG_VB_MEM=4096 vagrant up
```
 
- run the tests by explicitly raising the connection limit, by prefixing the
 `resty` executable and the new limit `-c 65000`, for example: 
```
resty -c 65000 bin/busted -v -o gtest
```
 
### Incompatible versions error

When Kong starts it can give errors for incompatible versions. This happens for
example when dependencies have been updated. Eg. 0.9.2 required Openresty
1.9.15.1, whilst 0.9.5 requires 1.11.2.1.

So please reprovision it and specify the proper version you want to work with
(either newer or older, see the defaults above), as in the example below with
version 0.9.2;

```shell
# clone this repository
$ git clone https://github.com/Kong/kong-vagrant
$ cd kong-vagrant/

# clone the Kong repo and switch explicitly to the 0.9.2 version.
# this will get the proper Kong source code for the version.
$ git clone https://github.com/Kong/kong
$ cd kong
$ git checkout 0.9.2
$ cd ..

# start a box with a folder synced to your local Kong clone, and
# specifically targetting 0.9.2, to get the required binary versions
$ KONG_VERSION=0.9.2 vagrant up
```

### Vagrant error; The box 'hashicorp/precise64' could not be found

There is a known issue with Vagrant on OS X with an included `curl` version
that fails. See [stack overflow](https://stackoverflow.com/questions/40473943/vagrant-box-could-not-be-found-or-could-not-be-accessed-in-the-remote-catalog)
for a solution.

## Enterprise Support

Support, Demo, Training, API Certifications and Consulting available at https://getkong.org/enterprise.

[kong-logo]: https://cl.ly/030V1u02090Q/unnamed.png
[website-url]: https://getkong.org/
[website-badge]: https://img.shields.io/badge/GETKong.org-Learn%20More-43bf58.svg
[documentation-url]: https://getkong.org/docs/
[documentation-badge]: https://img.shields.io/badge/Documentation-Read%20Online-green.svg
[gitter-url]: https://gitter.im/Mashape/kong
[gitter-badge]: https://img.shields.io/badge/Gitter-Join%20Chat-blue.svg
[mailing-list-badge]: https://img.shields.io/badge/Email-Join%20Mailing%20List-blue.svg
[mailing-list-url]: https://groups.google.com/forum/#!forum/konglayer
