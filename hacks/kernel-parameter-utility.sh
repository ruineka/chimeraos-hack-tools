#!/bin/bash

# Define the bootloader entry file
entry_file="/boot/loader/entries/frzr.conf"

# Define usage function
function usage() {
    echo "Usage: $0 [--append STRING_TO_APPEND | --remove STRING_TO_REMOVE | --list]"
}

# Check if the script was called with an option
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

# Check which option was specified
case "$1" in
    --append)
        # Define the string to append
        search_string="$2"

        # Check if the string is already present in the entry file
        if grep -qF "$search_string" "$entry_file"; then
            echo "The string '$search_string' is already present in $entry_file"
        else
            # If the string is not present, append it to the end of the kernel parameters
            echo "The string '$search_string' is not present in $entry_file"
            sed -i "/^options/ s~\$~ $search_string~" "$entry_file"
            echo "Added '$search_string' to the end of the kernel parameters in $entry_file"
        fi
        ;;
    --remove)
        # Define the string to remove
        remove_string="$2"

        # Check if the string is present in the entry file
        if grep -qF "$remove_string" "$entry_file"; then
            # If the string is present, remove it from the kernel parameters
            sed -i "s~ $remove_string~~" "$entry_file"
            echo "Removed '$remove_string' from the kernel parameters in $entry_file"
        else
            echo "The string '$remove_string' is not present in $entry_file"
        fi
        ;;
    --list)
        # Print the current kernel parameters
        echo "Current kernel parameters:"
        grep "^options" "$entry_file" | sed 's/^options //' | sed 's/\s*$//' | tr ' ' '\n'
        ;;
    *)
        usage
        exit 1
        ;;
esac

