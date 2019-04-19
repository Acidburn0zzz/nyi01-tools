chrootdir="/jenkins/chroot"
srcdir="/jenkins/src"

noclean=0

unmount_chroot() {
	# XXXOP hack ...
	for mount_point in ${chrootdir}/{usr/obj/usr/src/amd64.amd64/release/efi,dev,usr/src,usr/obj}; do
		if mount | grep ${mount_point} >/dev/null; then
			umount -f ${mount_point}
		fi
	done
}

destroy_chroot() {
	unmount_chroot

	if [ -d ${chrootdir} ]; then
		chflags -R noschg ${chrootdir}

		t=$(ls -A ${chrootdir} | tail -n 1)
		if [ ${#t} -gt 0 ]; then
			if [ -n ${chrootdir} ]; then
				set +e
				rm -rf ${chrootdir}/*
				set -e
			fi
		fi
	fi

	if [ ${noclean} -eq 0 ]; then
		if [  -d /usr/obj/jenkins/workspace/${JOB_NAME} ]; then
			chflags -R noschg /usr/obj/jenkins/workspace/${JOB_NAME}
			rm -rf /usr/obj/jenkins/workspace/${JOB_NAME}
		fi
	fi
}

mount_chroot() {
	unmount_chroot

	if [ ! -d ${chrootdir}/usr/src ]; then
		mkdir ${chrootdir}/usr/src
	fi

	if [ ! -d ${chrootdir}/usr/obj ]; then
		mkdir ${chrootdir}/usr/obj
	fi

	if [ ! -d /usr/obj/jenkins/workspace/${JOB_NAME} ]; then
		mkdir -p /usr/obj/jenkins/workspace/${JOB_NAME}
	fi

	mount -t devfs devfs ${chrootdir}/dev
	mount -t nullfs \
		/jenkins/workspace/${JOB_NAME} \
		${chrootdir}/usr/src
	mount -t nullfs \
		/usr/obj/jenkins/workspace/${JOB_NAME} \
		${chrootdir}/usr/obj
}

populate_chroot() {
	make -sC ${srcdir} \
		installworld \
		distribution \
		DESTDIR=${chrootdir}
}
