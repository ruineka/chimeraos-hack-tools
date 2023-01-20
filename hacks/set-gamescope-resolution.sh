#!/bin/bash
mkdir -p $HOME/.config/environment.d/
echo "
# Size of the screen. If not set gamescope will detect native resolution from drm.
SCREEN_HEIGHT=$2
SCREEN_WIDTH=$1

# Override entire Steam client command line
#STEAMCMD="steam -steamos -pipewire-dmabuf -gamepadui"

# Override the entire Gamescope command line
# This will not use screen and render sizes above
#GAMESCOPECMD="gamescope -e -f"
" > /$HOME/.config/environment.d/gamescope.conf
