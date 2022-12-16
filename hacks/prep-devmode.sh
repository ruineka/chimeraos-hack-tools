#!/bin/bash
#
# Cleans up a system after an upgrade and prepares it for development mode.

# unlock system
frzr-unlock

# Clean up outdated/breaking files
rm /etc/ld.so.conf.d/fakeroot.conf
rm -fr /etc/pacman.d/gnupg

# Setup new keyring
pacman-key --init
pacman-key --populate archlinux
pacman -S --noconfirm archlinux-keyring

# Install developer tools
pacman -S --noconfirm base-devel git cmake

# Install kernel headers
KERNEL=$(uname -r | sed '0,/-/{s/-/./}')
pacman -U --noconfirm 'https://archive.archlinux.org/packages/l/linux-headers/linux-headers-'$KERNEL'-x86_64.pkg.tar.zst'
