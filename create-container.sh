#!/usr/bin/bash -x

ETHDEV=eno1

# create_container(name, dest_port, route_to)
create_container() {
    lxc-create -t download -n ct-$1
    lxc-start -n ct-$1

    echo "enter into the shell:"
    echo "# apt install openssh-server && adduser $1 && adduser $1 sudo"

    lxc-attach -n ct-$1
    IP=$(lxc-info -n ct-$1 -iH)

    iptables -t nat -A PREROUTING -i $ETHDEV -p tcp --dport $2 -j DNAT --to $IP:22
    iptables-save > /etc/iptables/rules.v4

    echo "lxc.start.auto = 1" >> /var/lib/lxc/$1/config
}

# Example:
# create_container laddi 2208

