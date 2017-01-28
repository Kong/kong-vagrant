# [Kong][website-url] :heavy_plus_sign: [Vagrant](https://www.vagrantup.com/)

[![Website][website-badge]][website-url]
[![Documentation][documentation-badge]][documentation-url]
[![Mailing List][mailing-list-badge]][mailing-list-url]
[![Gitter Badge][gitter-badge]][gitter-url]

[![][kong-logo]][website-url]

Vagrant is used to create an isolated development environment for Kong 
including Postgres.

## Starting the environment

Once you have Vagrant installed, follow those steps:

```shell
# clone the Kong repo and switch to the next branch to use the latest, unrelease code
$ git clone https://github.com/Mashape/kong
$ cd kong
$ git checkout next

# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant/

# start a box with a folder synced to your local Kong clone
$ KONG_PATH=/path/to/kong/clone/ vagrant up
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
| `KONG_VERSION`  | the Kong version number to download and install at the provision step     | `0.9.5`  |
| `KONG_VB_MEM`   | virtual machine memory (RAM) size *(in MB)*                               | `512`    |


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

## Coding

The `lua_package_path` directive in the configuration specifies that the Lua 
code in your local folder will be used in favor of the system installation. 
The `lua_code_cache` directive being turned off, you can start Kong, edit your 
local files (on your host machine), and test your code without restarting Kong.

Eventually, familiarize yourself with the 
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
$ KONG_PATH=/path/to/kong/clone/ KONG_VERSION=0.9.2 vagrant up
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
