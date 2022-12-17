#!/bin/bash

### Create CHIMERA_UPDATE drive for repair installations or local deployments

device_list=()
device_output=`lsblk --list -n -o name,model,size,type | grep disk | tr -s ' ' '\t'`

while read -r line; do
	name=/dev/`echo "$line" | cut -f 1`
	model=`echo "$line" | cut -f 2`
	size=`echo "$line" | cut -f 3`
	device_list+=($name)
	device_list+=("$model ($size)")
done <<< "$device_output"

DISK=$(whiptail --nocancel --menu "Choose a disk to install to:" 20 50 5 "${device_list[@]}" 3>&1 1>&2 2>&3)

if ! (whiptail --yesno "WARNING: $DISK will now be formatted. All data on the disk will be lost. Do you wish to proceed?" 10 50); then
	echo "installation aborted"
	exit 1
fi

sudo mkfs -t ext4 -L CHIMERA_UPDATE $DISK
echo "Finished!"




