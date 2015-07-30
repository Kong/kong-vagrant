# Kong Vagrant

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

## Going further

From there, you can read futher development instructions in Kong's [README](https://github.com/Mashape/kong).

Other useful resources include:

- Documentation: [getkong.org/docs][kong-docs]
- Website: [getkong.org][kong-url]
- Mailing List: [Google Groups][google-groups-url]
- Gitter Chat: [Mashape/kong][gitter-url]

[kong-url]: http://getkong.org/
[kong-docs]: http://getkong.org/docs/

[gitter-url]: https://gitter.im/Mashape/kong

[google-groups-url]: https://groups.google.com/forum/#!forum/konglayer
