#!/usr/bin/bash -x

ETHDEV=$(route | grep '^default' | grep -o '[^ ]*$')

create_container() {
    local name=$1
    local dest_port=$2
    local ct_path="/var/lib/lxc/ct-$name/rootfs"

    exec <dist

    lxc-create -t download -n ct-$name
    lxc-start -n ct-$name
    sleep 4 # let it fully start

    lxc-attach -n ct-$name -- adduser --disabled-password --gecos ",,,," $name
    lxc-attach -n ct-$name -- adduser $name sudo
    lxc-attach -n ct-$name -- apt install openssh-server

    IP=$(lxc-info -n ct-$name -iH)

    iptables -t nat -A PREROUTING -i $ETHDEV -p tcp --dport $dest_port -j DNAT --to $IP:22
    iptables-save > /etc/iptables/rules.v4

    echo "lxc.start.auto = 1" >> /var/lib/lxc/ct-$name/config

    if $3; then
	    mkdir $ct_path/home/$name/.ssh 
        cp authorized_keys $ct_path/home/$name/.ssh/
        lxc-attach -n ct-$name -- chown $name -R /home/$name/.ssh
        lxc-attach -n ct-$name -- chgrp $name -R /home/$name/.ssh
    fi
}

