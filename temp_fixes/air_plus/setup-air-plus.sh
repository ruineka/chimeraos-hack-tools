#!/bin/bash

# Unlock filesystem
sudo frzr-unlock

# Grab dependencies
sudo pacman -S cpio iasl

# Setup DSDT
cd ~/
mkdir -p kernel/firmware/acpi/
curl -L -o ~/kernel/firmware/acpi/dsdt.dsl https://raw.githubusercontent.com/ruineka/chimeraos-hack-tools/main/temp_fixes/air_plus/ayaneo_air_plus.dsl
iasl -tc ~/kernel/firmware/acpi/dsdt.dsl
find kernel | cpio -H newc --create > acpi_override
sudo cp acpi_override /boot
sudo sed -i 's#linux /vmlinuz-linux#&\ninitrd /acpi_override#' /boot/loader/entries/frzr.conf
if [ -d ~/handygccs ]; then
   rm -rf ~/handygccs
fi
# Ensure we get the latest version of handygccs that actually supports the air-plus
git clone https://github.com/shadowblip/handygccs
cd ~/handygccs
sudo ./remove.sh
sudo ./install.sh


