# [KONG][website-url] :heavy_plus_sign: [Vagrant](https://www.vagrantup.com/)

[![Website][website-badge]][website-url]
[![Documentation][documentation-badge]][documentation-url]
[![Mailing List][mailing-list-badge]][mailing-list-url]
[![Gitter Badge][gitter-badge]][gitter-url]

[![][kong-logo]][website-url]

Vagrant is used to create an isolated development environment for Kong including Cassandra.

## Starting the environment

Once you have Vagrant installed, follow those steps:

```shell
# clone the Kong repo
$ git clone https://github.com/Mashape/kong

# clone this repository
$ git clone https://github.com/Mashape/kong-vagrant
$ cd kong-vagrant/

# start a box with a folder synced to your local Kong clone
$ KONG_PATH=/path/to/kong/clone/ vagrant up
```

This will tell Vagrant to mount your local Kong repository under the guest's `/kong` folder.

The startup process will install all the dependencies necessary for developing (including Cassandra). The kong source code is mounted at `/kong`. The host ports `8000` and `8001` will be forwarded to the Vagrant box.

## Building and running Kong

To build Kong execute the following commands:

```shell
# SSH into the vagrant box
$ vagrant ssh

# switch to the mounted Kong repo
$ cd /kong

# install Kong
$ sudo make dev

# start Kong
$ kong start -c kong_DEVELOPMENT.yml
```

## Testing Kong

To verify Kong is running successfully, execute the following command from the host machine:

```shell
curl http://localhost:8001
```

You should receive a JSON response:

```json
{
  "tagline": "Welcome to Kong",
  "version": "0.4.1",
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

The `lua_package_path` directive in the configuration specifies that the Lua code in your local folder will be used in favor of the system installation. The `lua_code_cache` directive being turned off, you can start Kong, edit your local files (on your host machine), and test your code without restarting Kong.

Eventually, familiariwe yourself with the [Makefile Operations](https://github.com/Mashape/kong#makefile-operations).

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
