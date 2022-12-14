#!/bin/bash

set -e
set -o pipefail

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

frzr-unlock

get_img_url() {
    CHANNEL=$1

    result=$(jq '[
          sort_by(.created_at) |
          reverse |
          .[] |
          { name: .name, prerelease: .prerelease, state: .assets[].state, url: .assets[].browser_download_url } |
          select(.url|test("img")) |
          select(.state=="uploaded")
        ]')

    if [ "$CHANNEL" == "testing" ]; then
        result=$(echo $result | jq '[ .[] | select(.name|test("UNSTABLE")|not) ]')
    elif [ "$CHANNEL" == "stable" ]; then
        result=$(echo $result | jq '[ .[] | select(.prerelease==false) ]')
    elif [ "$CHANNEL" != "unstable" ]; then
        result=$(echo $result | jq "[ .[] | select(.url|contains(\"-${CHANNEL}_\")) ]")
    fi

    echo $result | jq 'first | .url' | sed 's/"//g'
}

get_syslinux_dir() {
	local base=${1}

	# for legacy BIOS installations
	local result="${base}/boot/syslinux"

	if [ ! -d ${result} ]; then
		# for compatibility with older installations
		result="${base}/boot/EFI/syslinux"
	fi

	if [ ! -d ${result} ]; then
		# for new UEFI installations
		result="${base}/boot/EFI/BOOT"
	fi

	if [ ! -d ${result} ]; then
		result=""
	fi

	echo ${result}
}

get_syslinux_prefix() {
	local base=${1}
	local syslinux_dir=${2}

	realpath -m --relative-to=${syslinux_dir} ${base}/boot
}

get_syslinux_cfg() {
	local version=${1}
	local prefix=${2}
	local additional_initrd=${3}
	

echo "default ${version}
label ${version}
kernel ${prefix}/${version}/vmlinuz-linux
append root=LABEL=frzr_root rw rootflags=subvol=deployments/developer/${version} quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_priority=3 ibt=off
initrd ${additional_initrd}${prefix}/${version}/initramfs-linux.img"

}

get_deployment_to_delete() {
	local current_version=${1}
	local syslinux_cfg_path=${2}
	local deployment_path=${3}

	local TO_BOOT=`get_next_boot_deployment ${current_version} ${syslinux_cfg_path}`
	ls -1 ${deployment_path} | grep -v ${current_version} | grep -v ${TO_BOOT} | head -1 || echo
}

get_next_boot_deployment() {
	local current_version=${1}
	local syslinux_cfg_path=${2}

	local TO_BOOT='this-is-not-a-valid-version-string'
	if [ -f "${syslinux_cfg_path}" ] && grep "^default" "${syslinux_cfg_path}" > /dev/null; then
		TO_BOOT=`grep ^default ${syslinux_cfg_path} | sed 's/default //'`
	fi

	echo ${TO_BOOT}
}


main() {
	if [ $EUID -ne 0 ]; then
		echo "$(basename $0) must be run as root"
		exit 1
	fi

	MOUNT_PATH=/frzr_root

	if ! mountpoint -q ${MOUNT_PATH}; then
		MOUNT_PATH=/tmp/frzr_root
	fi

	if ! mountpoint -q ${MOUNT_PATH}; then
		mkdir -p ${MOUNT_PATH}
		mount -L frzr_root ${MOUNT_PATH}
		sleep 5
	fi

	if ! mountpoint -q ${MOUNT_PATH}/boot && ls -1 /dev/disk/by-label | grep frzr_efi > /dev/null; then
		mkdir -p ${MOUNT_PATH}/boot
		mount -L frzr_efi ${MOUNT_PATH}/boot
		sleep 5
	fi

	DEPLOY_PATH=${MOUNT_PATH}/deployments/developer
	mkdir -p ${DEPLOY_PATH}

	SYSLINUX_DIR=$(get_syslinux_dir ${MOUNT_PATH})

	if [ -z ${SYSLINUX_DIR} ]; then
		echo "No syslinux directory could be found"
		exit 1
	fi

	PREFIX=$(get_syslinux_prefix ${MOUNT_PATH} ${SYSLINUX_DIR})
	BOOT_CFG="${SYSLINUX_DIR}/syslinux.cfg"

	if [ "$1" == "--update-ready" ]; then
		CURRENT=`frzr-release`
		NEXT=`get_next_boot_deployment ${CURRENT} ${BOOT_CFG}`
		if [ ${NEXT} != ${CURRENT} ]; then
			exit 0
		fi

		exit 7
	fi

	# delete deployments under these conditions:
	# - we are currently running inside a frzr deployment (i.e. not during install)
	# - the deployment is not currently running
	# - the deployment is not configured to be run on next boot
	if frzr-release > /dev/null; then
		CURRENT=`frzr-release`
		TO_DELETE=`get_deployment_to_delete ${CURRENT} ${BOOT_CFG} ${DEPLOY_PATH}`

		if [ ! -z ${TO_DELETE} ]; then
			echo "deleting ${TO_DELETE}..."
			btrfs subvolume delete ${DEPLOY_PATH}/${TO_DELETE} || true
			rm -rf ${MOUNT_PATH}/boot/${TO_DELETE}
		fi
	fi

	if [ ! -z $1 ]; then
		echo "$1" > "${MOUNT_PATH}/source"
	fi

	if [ -e "${MOUNT_PATH}/source" ]; then
		SOURCE=`cat "${MOUNT_PATH}/source" | head -1`
	else
		echo "ERROR: no source specified"
		exit 1
	fi

	REPO=$(echo "${SOURCE}" | cut -f 1 -d ':')
	CHANNEL=$(echo "${SOURCE}" | cut -f 2 -d ':')

	RELEASES_URL="https://api.github.com/repos/${REPO}/releases"

	IMG_URL=$(curl --http1.1 -L -s "${RELEASES_URL}" | get_img_url "${CHANNEL}")

	if [ -z "$IMG_URL" ] || [ "$IMG_URL" == "null" ]; then
		echo "No matching source found"
		if curl --http1.1 -L -s "${RELEASES_URL}" | grep "rate limit" > /dev/null; then
			echo "GitHub API rate limit exceeded"
			exit 29
		fi
		exit 1
	fi

	FILE_NAME=$(basename ${IMG_URL})
	NAME=$(echo "${FILE_NAME}" | cut -f 1 -d '.')
	BASE_URL=$(dirname "${IMG_URL}")
	CHECKSUM=$(curl --http1.1 -L -s "${BASE_URL}/sha256sum.txt" | cut -f -1 -d ' ')
	SUBVOL="${DEPLOY_PATH}/${NAME}"
	IMG_FILE="${MOUNT_PATH}/${FILE_NAME}"

	if [ -e ${SUBVOL} ]; then
		echo "${NAME} already installed; aborting"
		exit
	fi

	if [ -z ${SHOW_UI} ]; then
		echo "downloading ${NAME}..."
		curl --http1.1 -L -o "${IMG_FILE}" -C - "${IMG_URL}"
	else
		curl --http1.1 -# -L -o "${IMG_FILE}" -C - "${IMG_URL}" 2>&1 | \
		stdbuf -oL tr '\r' '\n' | grep --line-buffered -oP '[0-9]*+(?=.[0-9])' | grep --line-buffered -v '100' | \
		whiptail --gauge "Downloading system image (${NAME})" 10 50 0
	fi

	CHECKSUM2=`sha256sum "${IMG_FILE}" | cut -d' ' -f 1`
	if [ "$CHECKSUM" != "$CHECKSUM2" ]; then
		rm -f "${IMG_FILE}"
		echo "checksum does not match; aborting"
		exit 1
	fi

	if [ -z ${SHOW_UI} ]; then
		echo "installing ${NAME}..."
	else
		whiptail --infobox "Extracting and installing system image (${NAME}). This may take some time." 10 50
	fi

	tar xfO ${IMG_FILE} | btrfs receive --quiet ${DEPLOY_PATH}
	mkdir -p ${MOUNT_PATH}/boot/${NAME}
	cp ${SUBVOL}/boot/vmlinuz-linux ${MOUNT_PATH}/boot/${NAME}
	cp ${SUBVOL}/boot/initramfs-linux.img ${MOUNT_PATH}/boot/${NAME}

	ADDITIONAL_INITRD=""
	if [ -e ${SUBVOL}/boot/amd-ucode.img ] ; then
		cp ${SUBVOL}/boot/amd-ucode.img ${MOUNT_PATH}/boot/${NAME}
		ADDITIONAL_INITRD="${ADDITIONAL_INITRD}${PREFIX}/${NAME}/amd-ucode.img,"
	fi
	if [ -e ${SUBVOL}/boot/intel-ucode.img ] ; then
		cp ${SUBVOL}/boot/intel-ucode.img ${MOUNT_PATH}/boot/${NAME}
		ADDITIONAL_INITRD="${ADDITIONAL_INITRD}${PREFIX}/${NAME}/intel-ucode.img,"
	fi

	get_syslinux_cfg ${NAME} ${PREFIX} ${ADDITIONAL_INITRD} > ${BOOT_CFG}

	rm -f ${MOUNT_PATH}/*.img.*

	rm -rf /var/lib/pacman # undo frzr-unlock

	echo "deployment complete; restart to boot into ${NAME}"

	if command -v frzr-postupdate-script > /dev/null; then
		frzr-postupdate-script
	fi

	umount -R ${MOUNT_PATH}
}


if [ "$0" = "$BASH_SOURCE" ] ; then
	main $1
fi

