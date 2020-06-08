#!/usr/bin/env bash

set -x

create_container() {
    local name=$1
    local dest_port=$2
    local withpasswd=$3
    
    local ct_path="/var/lib/lxc/ct-$name/rootfs"
    local ETHDEV=$(route | grep '^default' | grep -o '[^ ]*$')

    exec <dist

    cp /etc/lxc/default.conf ~/.config/lxc/default.conf
    echo "lxc.idmap = u 0 200000 65536" >> /root/.config/lxc/default.conf
    echo "lxc.idmap = g 0 200000 65536" >> /root/.config/lxc/default.conf

    lxc-create -n ct-"$name" -t download -- --no-validate
    lxc-start -n ct-"$name"
    sleep 4 # let it fully start

    if $withpasswd; then
        lxc-attach -n ct-"$name" -- adduser --gecos ",,,," "$name"
    else
        lxc-attach -n ct-"$name" -- adduser --disabled-password --gecos ",,,," "$name"
    fi

    lxc-attach -n ct-"$name" -- adduser "$name" sudo
    lxc-attach -n ct-"$name" -- apt install openssh-server

    local IP=$(lxc-info -n ct-"$name" -iH)

    iptables -t nat -A PREROUTING -i "$ETHDEV" -p tcp --dport "$dest_port" -j DNAT --to "$IP":22
    iptables-save > /etc/iptables/rules.v4

    echo "lxc.start.auto = 1" >> /var/lib/lxc/ct-"$name"/config

    if [ ! $withpasswd ]; then
        lxc-attach -n ct-"$name" -- mkdir /home/"$name"/.ssh
        cat authorized_keys | lxc-attach -n ct-"$name" \
            -- /bin/sh -c "/bin/cat > /home/$name/.ssh/authorized_keys"
        lxc-attach -n ct-"$name" -- chown "$name:$name" -R /home/"$name"/.ssh
    fi
}

lxc-destroy -fn ct-laddi
create_container laddi 2208 false

