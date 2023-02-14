#!/bin/bash

echo "Bios Date" | tee -a ~/dmi.log
cat /sys/class/dmi/id/bios_date | tee -a ~/dmi.log 

echo "Bios Version" | tee -a ~/dmi.log
cat /sys/class/dmi/id/bios_version | tee -a ~/dmi.log

echo "Bios Release" | tee -a ~/dmi.log
cat /sys/class/dmi/id/bios_release | tee -a ~/dmi.log

echo "Bios Vendor" | tee -a ~/dmi.log
cat /sys/class/dmi/id/bios_vendor | tee -a ~/dmi.log

echo "Product Name" | tee -a ~/dmi.log
cat /sys/class/dmi/id/product_name | tee -a ~/dmi.log

echo "Product SKU" | tee -a ~/dmi.log 
cat /sys/class/dmi/id/product_sku | tee -a ~/dmi.log

echo "Product Version" | tee -a ~/dmi.log 
cat /sys/class/dmi/id/product_version | tee -a ~/dmi.log

echo "System Vendor" | tee -a ~/dmi.log 
cat /sys/class/dmi/id/sys_vendor | tee -a ~/dmi.log 

echo "Firmware Release" | tee -a ~/dmi.log 
cat /sys/class/dmi/id/ec_firmware_release | tee -a ~/dmi.log

echo "The output results have been stored at ~/dmi.log"




