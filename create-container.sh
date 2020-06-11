#!/usr/bin/env bash

set -x

create_container() {
    local name="$1"
    local dest_port="$2"
    local opt="$3"    # only takes "withsk": with shared key

    local ETHDEV
    ETHDEV=$(route | grep '^default' | grep -o '[^ ]*$')

    cp /etc/lxc/default.conf /root/.config/lxc/default.conf
    echo "lxc.idmap = u 0 200000 65536" >> /root/.config/lxc/default.conf
    echo "lxc.idmap = g 0 200000 65536" >> /root/.config/lxc/default.conf

    lxc-create -n ct-"$name" -t download -- --no-validate -d ubuntu -r bionic -a amd64
    lxc-start -n ct-"$name"
    sleep 4 # let it fully start

    if [ "$opt" = "withsk" ]; then
        lxc-attach -n ct-"$name" -- adduser --disabled-password --gecos ",,,," "$name"
    else
        lxc-attach -n ct-"$name" -- adduser --gecos ",,,," "$name"
    fi

    lxc-attach -n ct-"$name" -- adduser "$name" sudo
    lxc-attach -n ct-"$name" -- apt install openssh-server

    local IP
    IP=$(lxc-info -n ct-"$name" -iH)

    iptables -t nat -A PREROUTING -i "$ETHDEV" -p tcp --dport "$dest_port" -j DNAT --to "$IP":22
    iptables-save > /etc/iptables/rules.v4

    echo "lxc.start.auto = 1" >> /var/lib/lxc/ct-"$name"/config

    if [ "$opt" = "withsk" ]; then
        lxc-attach -n ct-"$name" -- mkdir /home/"$name"/.ssh
        lxc-attach -n ct-"$name" -- /bin/sh -c \
                   "/bin/cat > /home/$name/.ssh/authorized_keys" < authorized_keys
        lxc-attach -n ct-"$name" -- chown "$name:$name" -R /home/"$name"/.ssh
    fi
}

if [ "$#" = 0 ]; then
    exit
else
    create_container "$@"
fi

