#!/bin/sh

set -ex

. /jenkins/scripts/jail.sh

target="SHOULD_FAIL"
targetdir=""
kernel="HARDENEDBSD"
date="`date "+%Y%m%d%H%M"`"
#export __MAKE_CONF="/dev/null"
#export __SRC_CONF="/dev/null"
#export MAKE_CONF="/dev/null"
#export SRC_CONF="/dev/null"

#_L_JOB_NAME=`echo ${JOB_NAME} | tr '[:upper:]' '[:lower:]'`
_INSTALLER_PREFIX="${JOB_NAME}-s${date}-"

_TAR_DIR="/jenkins/releases/${JOB_NAME}/build-${BUILD_NUMBER}/"
_ISO_DIR="${_TAR_DIR}/ISO-IMAGES"

while getopts 't:' o; do
    case "${o}" in
        t)
            if [ ! "${OPTARG}" = "${target}" ]; then
                case "${OPTARG}" in
		    amd64)
			reltarget="amd64.amd64"
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			;;
		    arm64)
			reltarget="arm64.aarch64"
			target="TARGET=arm64 TARGET_ARCH=aarch64"
			targetdir="arm64"
			;;
                    i386)
			reltarget="i386.i386"
                        target="TARGET=i386 TARGET_ARCH=i386"
                        targetdir="i386"
                        ;;
		    opbsd-fortify-amd64)
			reltarget="amd64.amd64"
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			kernel="GENERIC"
			_INSTALLER_PREFIX="opBSD-11-CURRENT_${_L_JOB_NAME}-"
			;;
                    defaut)
                        echo "Invalid target!"
                        exit 1
                        ;;
                esac
            fi
            ;;
    esac
done

build_release() {
	chroot ${chrootdir} \
		make -C /usr/src/release \
			-s \
			${target} \
			clean
	chroot ${chrootdir} \
		make -C /usr/src/release \
			${target} \
			obj
	chroot ${chrootdir} \
		make -C /usr/src/release \
			-s \
			KERNCONF=${kernel} \
			NOPORTS=1 \
			${target} \
			real-release
}

copy_release() {
	if [ ! -d ${_TAR_DIR} ]; then
	    mkdir -p ${_TAR_DIR}
	fi

	if [ ! -d ${_ISO_DIR} ]; then
	    mkdir -p ${_ISO_DIR}
	fi

	reldir="/usr/obj/jenkins/workspace/${JOB_NAME}/usr/src/release"
	if [ ! -d ${reldir} ]; then
		reldir="/usr/obj/jenkins/workspace/${JOB_NAME}/usr/src/${reltarget}/release"
		if [ ! -d ${reldir} ]; then
			echo "[-] Release directory ${reldir} not found!"
			return 1
		fi
	fi

	# iso and img file - aka installers
	for file in $(find ${reldir} -maxdepth 1 -name '*.iso' -o -name '*.img'); do
	    _dst_file="${_ISO_DIR}/${_INSTALLER_PREFIX}${file##*/}"
	    cp -v ${file} ${_dst_file}
	    sha256 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.SHA256
	    sha512 ${_dst_file} >> ${_ISO_DIR}/CHECKSUMS.SHA512
	    gpg --sign -a --detach -u BB53388D3BD9892815CB9E30819B11A26FFD188D -o ${_ISO_DIR}/$(basename ${_dst_file}).asc ${_dst_file}
	done
	#
	# archives - aka part of installers
	for file in $(find ${reldir} -maxdepth 1 -name '*.txz' -or -name 'MANIFEST'); do
	    cp -v ${file} ${_TAR_DIR}
	    sha256 ${file} >> ${_TAR_DIR}/CHECKSUMS.SHA256
	    sha512 ${file} >> ${_TAR_DIR}/CHECKSUMS.SHA512
	    gpg --sign -a --detach -u BB53388D3BD9892815CB9E30819B11A26FFD188D -o ${_TAR_DIR}/$(basename ${file}).asc ${file}
	done

	return 0
}

main() {
	env
	mount_chroot
	build_release
	unmount_chroot
	copy_release

	ln -fhs ${_TAR_DIR} "/jenkins/releases/${JOB_NAME}-LATEST"
}

main
