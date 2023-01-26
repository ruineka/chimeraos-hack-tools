#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

frzr-unlock
pacman -Sy linux-zen linux-zen-headers

mv /boot/initramfs-linux-zen.img /boot/chimeraos*/initramfs-linux.img 
mv /boot/vmlinuz-linux-zen /boot/chimeraos*/vmlinuz-linux
rm /boot/initramfs-linux-zen-fallback.img
