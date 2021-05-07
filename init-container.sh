#!/bin/bash

set -e

###
### install cri-o
###

OS="xUbuntu_20.04"
VERSION="1.20"

cat <<EOF | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF

cat <<EOF | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | \
	apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | \
	apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -

apt-get update
apt-get install -y cri-o cri-o-runc
apt-get install -y zfsutils-linux

sed -i 's/driver = ".*"/driver = "zfs"/' /etc/containers/storage.conf

systemctl enable crio

###
### Install kubernetes
###
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

###
### setup openvpn
###

apt-get install -y openvpn
sed -i '/^#.*AUTOSTART="all" /s/^#//' /etc/default/openvpn
systemctl enable openvpn@client

