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
sed -i 's/SigLevel    = Required DatabaseOptional/SigLevel = Never/g' /etc/pacman.conf
KERNEL_VER=$(uname -r | sed '0,/-/{s/-/./}' | sed 's/chimeraos/chos/g' | sed 's/chos-/chos/g' )
KERNEL_FOLDER=$(uname -r | sed '0,/-/{s/-/./}' | sed 's/chimeraos/chos/g' | sed 's/.chos-/-chos/g' )
HEADERS_FILE='https://github.com/ChimeraOS/linux-chimeraos/releases/download/'$KERNEL_FOLDER'/linux-chimeraos-headers-'$KERNEL_VER'-1-x86_64.pkg.tar.zst'
pacman -U --noconfirm $HEADERS_FILE
