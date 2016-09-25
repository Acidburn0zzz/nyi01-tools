#!/bin/sh

set -ex

. /jenkins/scripts/jail.sh

target="SHOULD_FAIL"
targetdir=""
kernel="HARDENEDBSD"
export __MAKE_CONF="/dev/null"
export __SRC_CONF="/dev/null"
export MAKE_CONF="/dev/null"
export SRC_CONF="/dev/null"

while getopts 't:' o; do
    case "${o}" in
        t)
            if [ ! "${OPTARG}" = "${target}" ]; then
                case "${OPTARG}" in
		    amd64)
			target="TARGET=amd64 TARGET_ARCH=amd64"
			targetdir="amd64"
			;;
                    i386)
                        target="TARGET=i386 TARGET_ARCH=i386"
                        targetdir="i386"
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

mount_chroot
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
unmount_chroot

echo "for installer images and distfiles see http://installer.hardenedbsd.org"
