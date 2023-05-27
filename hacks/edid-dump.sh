#!/bin/bash

# Create the target directory if it doesn't exist
mkdir -p "$HOME/edid/"

product_name=$(cat /sys/class/dmi/id/product_name)

# Find all files named 'edid' under /sys/devices
find /sys/devices -name 'edid' | while read -r file; do
    # Check if the EDID file is empty
    if ! grep -q . "$file"; then
        echo "$file is empty. Skipping..."
        continue
    fi

    dir=$(dirname "$file")

    device_name=$(basename "$dir")

    # Generate a unique filename based on the device name and DMI product name with .bin extension
    filename="${product_name}-${device_name}_edid.bin"

    cp "$file" "$HOME/edid/$filename"
    
    # Change the permissions of the copied file to read-write (RW)
    chmod +rw "$HOME/edid/$filename"
done

