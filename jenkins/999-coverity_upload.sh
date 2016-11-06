#!/usr/bin/env bash

TAR_NAME=/tmp/HardenedBSD.tbz

WORKSPACE=$1
DESC=$2
COVERITY_TOKEN=`cat /jenkins/scripts/.coverity_token`
COVERITY_MAIL=`cat /jenkins/scripts/.coverity_mail`

echo "wd:${WORKSPACE} desc:${DESC}"

if [ ! -d ${WORKSPACE} ]
then
	echo "failed to change the current directory to ${WORKSPACE}"
	return 1
fi

cd ${WORKSPACE}

tail cov-int/build-log.txt

tar cjvf ${TAR_NAME} cov-int

curl --form token=${COVERITY_TOKEN} \
	--form email=${COVERITY_MAIL} \
	--form file=@${TAR_NAME} \
	--form version="10-STABLE" \
	--form description="${DESC} `date`" \
	https://scan.coverity.com/builds?project=HardenedBSD
_ret=$?

if [ ${_ret} = 0 ]
then
	if [ -d ${WORKSPACE}/cov-int ]
	then
		rm -rf ${WORKSPACE}/cov-int
	fi

	if [ -f ${TAR_NAME} ]
	then
		rm -f ${TAR_NAME}
	fi
else
	exit ${_ret}
fi
