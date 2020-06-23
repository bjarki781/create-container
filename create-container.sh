#!/usr/bin/env bash

set -x

create_container() {
    if [ "$#" != 3 ]; then
        return 1
    fi

    local name="$1"
    local dest_port="$2"
    local opt="$3"    # only takes "withsk": with shared key

    local ETHDEV=$(route | grep '^default' | grep -o '[^ ]*$')

    mkdir -p /root/.config/lxc
    cp /etc/lxc/default.conf /root/.config/lxc/default.conf
    # the containers act as if they are the first normal user on the host
    echo "lxc.idmap = u 0 100000 65536" >> /root/.config/lxc/default.conf
    echo "lxc.idmap = g 0 100000 65536" >> /root/.config/lxc/default.conf

    lxc-create -n ct-"$name" -t download -- --no-validate -d ubuntu -r bionic -a amd64
    lxc-start -n ct-"$name"
    sleep 4 # let it fully start

    if [ "$opt" = "withsk" ]; then
        lxc-attach -n ct-"$name" -- adduser --disabled-password --gecos ",,,," "$name"
        # if we log in using only keys then the root account can be open
        lxc-attach -n ct-"$name" -- passwd root <<< $(echo -e "smile\nsmile")
    else
        lxc-attach -n ct-"$name" -- adduser --gecos ",,,," "$name"
        lxc-attach -n ct-"$name" -- adduser "$name" sudo
    fi

    lxc-attach -n ct-"$name" -- apt -y install openssh-server

    local IP=$(lxc-info -n ct-"$name" -iH)

    mkdir -p /etc/iptables
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

if [ $# = 3 ]; then
    create_container "$@"
fi
