#!/bin/bash

set -e

script_directory=`dirname $0`
container_system="ubuntu:20.04"
container_name="iceblock-kubernetes"
container_hostname="$1"

if [ -z "$container_hostname" ]; then
	echo "Container name was not set. Call launch.sh <container name>"
	exit 1;
fi

# TODO test if lxd available, lxd init

if ! sudo lxc profile show iceblock 2>&1 >> /dev/null; then
	sudo lxc profile create iceblock
fi

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

echo "edit iceblock profile"
cat $script_directory/iceblock.profile | sudo lxc profile edit iceblock
echo "init container"
sudo lxc init --profile default --profile iceblock $container_system $container_name
#echo "allow nesting"
#sudo lxc config set $container_name security.nesting true

echo "push init script"
sudo lxc file push $script_directory/init-container.sh $container_name/

echo "setup cloud init script"
sudo lxc config set $container_name user.user-data - < $script_directory/cloud-init.xml

sudo lxc start $container_name

sudo lxc exec $container_name -- sysctl kernel.hostname=$container_hostname

echo "vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
echo "vim /etc/openvpn/client.conf"

