#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

frzr-unlock
pacman -Sy linux linux-headers

mv /boot/initramfs-linux.img /boot/chimeraos*/initramfs-linux.img 
mv /boot/vmlinuz-linux /boot/chimeraos*/vmlinuz-linux
rm /boot/initramfs-linux-fallback.img
