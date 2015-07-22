#!/bin/sh

MASTER_IP=$1

########################################################################

docker ps | grep -q etcd
if [ $? -ne 0 ] ; then
	logger -t "master-provision" "Starting etcd"
	docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs \
		-p 4001:4001 -p 2380:2380 -p 2379:2379 \
		--name etcd quay.io/coreos/etcd:v2.0.8 \
		-name etcd0 \
		-advertise-client-urls http://${MASTER_IP}:2379,http://${MASTER_IP}:4001 \
		-listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
		-initial-advertise-peer-urls http://${MASTER_IP}:2380 \
		-listen-peer-urls http://0.0.0.0:2380 \
		-initial-cluster-token etcd-cluster-1 \
		-initial-cluster etcd0=http://${MASTER_IP}:2380 \
		-initial-cluster-state new

	# Create the swarm directory
	sleep 3 && curl -L http://127.0.0.1:4001/v2/keys/swarm -XPUT -d dir=true

	# get all the keys with:
	# curl -L http://127.0.0.1:4001/v2/keys/swarm?recursive=true
fi

docker ps | grep -q swarm 2>/dev/null
if [ $? -ne 0 ] ; then
	logger -t "master-provision" "Starting swarm master in background"
	daemon --name=swarm --respawn -- \
		docker run --name=swarm swarm manage etcd://$MASTER_IP:4001/swarm
fi

