#!/usr/bin/env bash

# simple testing scenario with the help of docker-machine
# - creates 2 VMs with
#    - docker, Weave and Discovery
# - creates a token
# - both VMs join the same token
# - and we show the Weave logs (if "--check")

[ -n "$WEAVE_DEBUG" ] && set -x

CHECK=
STOP=
MACHINES="h1 h2"
FILES="../discovery ../weavediscovery.tar"
REMOTE_ROOT=/home/docker
WEAVE=/usr/local/bin/weave
WEAVER_PORT=6783
TOKEN=

log() { echo ">>> $1" >&2 ; }

############################
# main
############################

while [ $# -gt 0 ] ; do
    case "$1" in
        -check|--check)
            CHECK=1
            ;;
        --token)
            TOKEN="$2"
            shift
            ;;
        --token=*)
            TOKEN="${1#*=}"
            ;;
        --stop)
            STOP=1
            ;;
        *)
            break
            ;;
    esac
    shift
done

# Get a token
[ -z "$TOKEN" ] && TOKEN=$(curl --silent -X POST https://discovery-stage.hub.docker.com/v1/clusters)

# Create two machines
for machine in $MACHINES ; do
    docker-machine status $machine >/dev/null
    if [ $? -ne 0 ] ; then
        log "Creating VirtualBox $machine..."
        docker-machine create --driver virtualbox   h1
    fi
done

# Build and upload Discovery
log "Building..."
make -C ..

log "Installing Discovery..."
for machine in $MACHINES ; do
    for file in $FILES ; do
        docker-machine scp $file $machine:$REMOTE_ROOT/ >/dev/null
    done
    docker-machine ssh $machine "docker load -i $REMOTE_ROOT/weavediscovery.tar"
done

for machine in $MACHINES ; do
    advertise=$(docker-machine ip $machine):$WEAVER_PORT

    SCRIPT=$(tempfile)
    cat <<EOF > $SCRIPT
#!/bin/sh
if [ -x $WEAVE ] ; then
    weave stop || /bin/true
    if [[ "$(curl --silent -L git.io/weave -z $WEAVE -o $WEAVE -s -L -w %{http_code})" == "200" ]]; then
        sudo chmod a+x $WEAVE
    fi
else
    curl --silent -L git.io/weave -o $WEAVE
    sudo chmod a+x $WEAVE
fi
weave launch

docker stop weavediscovery || /bin/true
$REMOTE_ROOT/discovery join --advertise=$advertise token://$TOKEN
EOF

    log "Provisioning $machine ($advertise)..."
    docker-machine scp $SCRIPT $machine:$REMOTE_ROOT/provision.sh >/dev/null
    docker-machine ssh $machine sh $REMOTE_ROOT/provision.sh
    rm -f $SCRIPT
done

if [ -n "$CHECK" ] ; then
    sleep 2
    for machine in $MACHINES ; do
        log " --- Weave @ $machine ---"
        eval "$(docker-machine env $machine)"
        docker logs weave
    done
fi

if [ -n "$STOP" ] ; then
    for machine in $MACHINES ; do
        eval "$(docker-machine env $machine)"
        log "Stoping Discovery at $machine"
        docker stop weavediscovery
    done
fi