#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# This will blacklist the mt76x2u module
echo "blacklisting mt76x2u module"
echo "blacklist mt76x2u" | tee /etc/modprobe.d/xone-blacklist.conf
systemctl restart systemd-modules-load.service


