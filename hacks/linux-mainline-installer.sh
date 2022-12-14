#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

frzr-unlock

# Adding miffe repo
# add miffe repo and keys
pacman-key --init
pacman-key --recv-keys 313F5ABD
pacman-key --lsign-key 313F5ABD

echo '
[miffe]
Server = http://arch.miffe.org/x86_64/
' >> /etc/pacman.conf

pacman -Sy linux-mainline linux-mainline-headers

cp /boot/initramfs-linux-mainline /boot/chimeraos*/initramfs-linux.img 
cp /boot/vmlinuz-linux-mainline /boot/chimeraos*/vmlinuz-linux
