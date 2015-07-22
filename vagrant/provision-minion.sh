#!/bin/sh

MINION_INDEX=$1
MINION_IP=$2
NUM_MINIONS=$3
MASTER_IP=$4

########################################################################

docker ps | grep -q swarm 2>/dev/null
if [ $? -ne 0 ] ; then
	logger -t "minion-provision" "Starting swarm in background"
	daemon --name=swarm --respawn -- \
		docker run swarm join etcd://$MASTER_IP:4001/swarm \
			--addr $MINION_IP:2375
fi

if [ ! -f /usr/local/bin/weave ] ; then
	logger -t "minion-provision" "Installing Weave"
	sudo curl -s -L git.io/weave -o /usr/local/bin/weave
	sudo chmod a+x /usr/local/bin/weave
fi

logger -t "minion-provision" "Launching Weave"
/usr/local/bin/weave launch       || /bin/true
/usr/local/bin/weave launch-dns   || /bin/true
/usr/local/bin/weave launch-proxy || /bin/true

# logger -t "minion-provision" "Launching an Ubuntu container"
# eval $(weave proxy-env)
# docker run --name "minion${MINION_INDEX}" -ti ubuntu

