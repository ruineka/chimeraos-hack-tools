#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

if [ -z "$(which iasl)" ]; then 
	echo "ACPICA tools not installed. Install them by running 'pacman -S acpica'";
	exit 1
else 
	echo "ACPICA tools installed. Continuing..."; 
fi

ACPI_DIR="/home/$SUDO_USER/acpi"

mkdir $ACPI_DIR
cd /sys/firmware/acpi/tables/
for f in ./*; do 
	echo "$f:"; 
	cat $f > $ACPI_DIR/$f.dat; 
done

cd $ACPI_DIR
for f in ./*; do 
	echo "$f:"; 
	iasl -d $f; 
done

cd ..

tar -cf acpi_dump.tar acpi

