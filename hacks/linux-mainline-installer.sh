#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

frzr-unlock

# Adding miffe repo
# add miffe repo and keys

if ! grep -q "Server = http://arch.miffe.org/x86_64/" "/etc/pacman.conf" ; then

echo 'adding miffe repo to pacman.conf'
pacman-key --init
pacman-key --recv-keys 313F5ABD
pacman-key --lsign-key 313F5ABD

echo '
[miffe]
Server = http://arch.miffe.org/x86_64/
' >> /etc/pacman.conf

fi


pacman -Sy linux-mainline linux-mainline-headers

mv /boot/initramfs-linux-mainline.img /boot/chimeraos*/initramfs-linux.img 
mv /boot/vmlinuz-linux-mainline /boot/chimeraos*/vmlinuz-linux
rm /boot/initramfs-linux-mainline-fallback.img
