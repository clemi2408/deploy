# deploy

- [maaspower](https://github.com/gilesknap/maaspower)
- [MaaS](http://maas.io) (DB, Region, Rack)
- [lxd](https://github.com/lxc/lxd)
- [Juju](http://maas.io) (Client, Controller)

Parameters:

- `install`: installs MaaS
- `remove`: removes MaaS
- `installController`: installs Juju Controller on MaaS
- `removeController`: removes Juju Controller on MaaS
- `configFile`: see [example.config](example.config)

Call:

```
./seed.sh {install|remove|installController|removeController} configFile
```
