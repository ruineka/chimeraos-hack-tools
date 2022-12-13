#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

# Change $kernel_parameters to whatever you want to be set for your kernel
kernel_parameters="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_priority=3 ibt=off split_lock_detect=off"

mkdir -p /run/media/boot
mount /dev/nvme0n1p1 /run/media/boot

sed -i "s/quiet splash/${kernel_parameters}/g" /run/media/boot/EFI/BOOT/syslinux.cfg
umount -l /run/media/boot
rm -r /run/media/boot

echo "done, reboot for your changes to take effect"
