Discovery
=========

Weave Discovery retrieves and watches a list of peers
available in a Weave network from a discovery backend.
Discovery uses this information for telling a Weave Router
about new peers it must connect to, as well as peers
that are not available anymore and must be forgotten.
Discovery will also advertise the Weave router in the
same backend so other peers can join it.

The backends used by Discovery are compatible with
[Docker Swarm](https://github.com/docker/swarm), so
you could use Discovery for keeping the connectivity
of members of this clustering technology.


Installation
============

Just download the `discovery` script from the repository,
or use this short URL:

```
curl -O http://git.io/vmW3z
chmod a+x discovery
```

This will download the `discovery` script to the current
directory.

Usage
=====

Once you have the script, joining a new discovery URL
is as simple as running:

```
$ ./discovery join <URL>
```

The endpoint URL can be something like

- `etcd://<etcd_ip>/<path>`
- `consul://<consul_addr>/<path>`
- `zk://<zookeeper_addr1>,<zookeeper_addr2>/<path>`
- `token://<swarm_cluster_id>`

Example:

```
$ ./discovery join etcd://192.168.9.1/mycluster
```

You can get more information about the supported backends
as well as the URL formats [here](https://github.com/docker/swarm/tree/master/discovery).

By default, Discovery will configure the Weave router in the
local machine. However, you can point Discovery to a
different router with the `--weave` flag.

For example, we can point Discovery to the Weave HTTP
API found at _192.168.9.3:6784_ with:

```
$ ./discovery join --weave=192.168.9.3:6784 etcd://192.168.9.1/mycluster
```

The router will also be advertised to other peers by
Discovery by publishing a reachable IP in the same discovery
endpoint, so other peers will be able to find it.
Discovery guesses the advertised IP by trying _1)_ the
router's adress (when using a non-local router) _2)_ the
interface that is used for the default route. However,
you should probably overide this and make it explicit
with the `--advertise` flag.

Example:

```
$ ./discovery join --advertise=193.144.60.100 etcd://192.168.9.1/mycluster
```

Discovery can also advertise the guessed external IP with
the `--advertise-external` flag. However this will not perform
any NAT mapping, so make sure the router is accessible at this
IP _and_ port by the rest of the peers in the backend.


