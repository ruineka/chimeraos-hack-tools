#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi
## Handling mkinitpio -P sucks on ChimeraOS..lets fix that
cp /boot/chimeraos-*/* /boot

mkinitcpio -P

cp -a /boot/initramfs-linux.img /boot/chimeraos-*/

rm /boot/initramfs*

rm /boot/vmlinuz-linux
