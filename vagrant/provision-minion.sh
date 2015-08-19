#!/bin/sh

MINION_INDEX=$1
MINION_IP=$2
NUM_MINIONS=$3
SWARM_TOKEN=$4

DISCOVERY_DIR=/vagrant
DEFAULT_WEAVER_PORT=6784
WEAVE=/usr/local/bin/weave

########################################################################

info() { echo "$1" ; logger -t "minion-provision" "$1" ; }
docker_stop() { docker stop $1 2>/dev/null || /bin/true ; docker rm $1 2>/dev/null || /bin/true ; }

info "###### Provisioning machine ${MINION_INDEX} ######"

info "Installing/updating Weave"
sudo curl -s -L git.io/weave -z $WEAVE -o $WEAVE
sudo chmod a+x $WEAVE

init_pc=$NUM_MINIONS

info "Launching Weave"
$WEAVE stop             2>/dev/null || /bin/true
$WEAVE stop-proxy       2>/dev/null || /bin/true
sleep 1
$WEAVE launch       -initpeercount $init_pc
$WEAVE launch-proxy

info "Launching a Swarm slave (token: ${SWARM_TOKEN})"
docker_stop swarm-agent
docker run \
    -d \
    --restart=always \
    --name=swarm-agent \
    swarm join \
    --addr "${MINION_IP}:12375" \
    "token://${SWARM_TOKEN}"

info "Installing Discovery"
docker_stop weavediscovery
docker load -i $DISCOVERY_DIR/weavediscovery.tar

# NOTE: we do not register ourselves in the discovery backend (we leave that task to Swarm),
#       so the <IP:port>s will have the right IPs, but the port will be the one Swarm wanted.
#       We must use "--discovered-port" for forcing the port where the Router is listening at...
info "Launching Discovery (token: ${SWARM_TOKEN})"
$DISCOVERY_DIR/discovery join \
    --discovered-port=$DEFAULT_WEAVER_PORT \
    "token://${SWARM_TOKEN}"

info "We are done with machine #${MINION_INDEX}."
info "You should see ${MINION_IP} when doing a 'swarm list token://${SWARM_TOKEN}'"
info "When all minions are up and running, you can run:"
info " * docker run -d -p 22375:2375 swarm manage token://${SWARM_TOKEN}"
info " * docker -H 127.0.0.1:22375 info"


