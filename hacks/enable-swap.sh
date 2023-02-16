#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

cd /user/gamer

if [ ! -f /home/gamer/swapfile ] ; then
        truncate -s 0 swapfile
        chattr +C swapfile
        fallocate -l 4G swapfile
        chmod 0600 swapfile
        mkswap swapfile
        swapon swapfile
else
        echo "swapfile already exists, exiting"
        exit 0
fi


echo "/home/gamer/swapfile        none        swap        defaults      0 0" >> /etc/fstab

echo "Reboot for changes to take effect"

