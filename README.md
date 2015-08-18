Discovery
=========

Weave Discovery retrieves and watches a list of peers
available in a Weave network from a discovery backend.
Discovery uses this information for telling a Weave Router
about new peers it must connect to, as well as peers
that are not available anymore and must be forgotten.
Discovery will also advertise the Weave router in the
same backend so other peers can join it.

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

Discovery will not try to advertise the Router to other
peers by default.  a reachable IP in the same discovery
endpoint, so other peers will be able to find it.
Discovery guesses the advertised IP by trying _1)_ the
router's adress (when using a non-local router) _2)_ the
interface that is used for the default route. However,
you should probably overide this and make it explicit
with the `--advertise` flag.

Example:

```
$ ./discovery join --advertise=193.144.60.100:6784 etcd://192.168.9.1/mycluster
```

Discovery can also advertise the guessed external IP with
the `--advertise-external` flag. However this will not perform
any NAT mapping, so make sure the router is accessible at this
IP _and_ port by the rest of the peers in the backend.


Example
=======

A Vagrant file has been included for testing the functionaly
of Discovery. The Vagrant will start three VMs with: 

  * a Weave router and proxy
  * a Swarm agent that uses some _token_ and points to the Weave proxy
  * a Discovery instance that uses the same _token_ and points to the Weave router

You can launch the Vagrant VMs with:

```
	$ vagrant up --provision
```

Machines will be provisioned and a new Swarm token ID will be
automatically generated. You will see the ID in the console messages.
After a few seconds, you will be able to check the list of peers
that have successfully registered in this token with:

```
	$ swarm list token://TOKEN
	10.246.2.3:12375
	10.246.2.4:12375
	10.246.2.2:12375
```

In the host machine (not in the Vagrants), you can start the cluster
manager with:

```
	$ docker run -d -p 22375:2375 swarm manage token://TOKEN"
```

This manager can be reachable at port 22375. Point your Docker client to
this port for getting the list of the machines in the cluster, with:

```
	$ docker -H 127.0.0.1:22375 info
	
	Containers: 17
    Images: 26
    Storage Driver: 
    Role: primary
    Strategy: spread
    Filters: affinity, health, constraint, port, dependency
    Nodes: 3
     minion-0: 10.246.2.2:12375
      └ Containers: 6
      └ Reserved CPUs: 0 / 2
      └ Reserved Memory: 0 B / 2.052 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-21-generic, operatingsystem=Ubuntu 15.04, storagedriver=overlay
     minion-1: 10.246.2.3:12375
      └ Containers: 6
      └ Reserved CPUs: 0 / 2
      └ Reserved Memory: 0 B / 2.052 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-21-generic, operatingsystem=Ubuntu 15.04, storagedriver=overlay
     minion-2: 10.246.2.4:12375
      └ Containers: 5
      └ Reserved CPUs: 0 / 2
      └ Reserved Memory: 0 B / 2.052 GiB
      └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-21-generic, operatingsystem=Ubuntu 15.04, storagedriver=overlay
    Execution Driver: 
    Kernel Version: 
    Operating System: 
    CPUs: 6
    Total Memory: 6.155 GiB
    Name: 
    ID: 
```

Now you can run a Ubuntu shell in _some_ machine in the cluster, with:

```
	$ docker -H 127.0.0.1:22375 run -ti  ubuntu
	root@7f1007c28c1c:/# 
```

