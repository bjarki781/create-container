#!/usr/bin/bash

ETHDEV=eno1

# create_container(name, dest_port, route_to)
create_container() {
    lxc-create -t download -n $1
    lxc-start -n $1
    lxc-attach -n $1 --clear-env -- "init 2; /usr/bin/apt install openssh-server"
    IP=$(lxc-info -n $1 -iH)

    echo "iptables -t nat -A PREROUTING -i $ETHDEV -p tcp --dport $2 -j DNAT --to $IP:22" \
        > /etc/network/iptables.rules.v4
}

create_container miner 2229
create_container dev   2231

