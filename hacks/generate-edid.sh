#!/bin/bash

for f in `find /sys/devices -name 'edid'`; do cat $f| edid-decode;done
