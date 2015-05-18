#!/usr/bin/env bash
#
# Note that I use this script to update all my current stages, and rootfs,
# but this repo is more specifically for Gentoo, so have some Gentoo.

##
## Vars
##
MIRROR="https://lug.mtu.edu"
OUTDIR="/var/tmp/catalyst/builds"

mkdir -p ${OUTDIR}

##
## Gentoo
##

STAGE3_NAME="stage3-amd64-latest.tar.bz2"
STAGE3_FILE=$(curl -s "${MIRROR}/gentoo/releases/amd64/autobuilds/latest-stage3-amd64.txt" | awk '/stage3/ { print $1 }')
LIVE_SHA512=$(curl -s "${MIRROR}/gentoo/releases/amd64/autobuilds/${STAGE3_FILE}.DIGESTS" | awk '/SHA512 HASH/{getline;print}' | grep -iv 'contents' | awk {'print $1'})
OUR_SHA512=$(sha512sum "${OUTDIR}/${STAGE3_NAME}" | awk {'print $1'})

# download latest stage3 if not the newest
if [ "${LIVE_SHA512}" != "${OUR_SHA512}" ]
then
	echo "Downloading new image - ${STAGE3_NAME}"
	curl -s "${MIRROR}/gentoo/releases/amd64/autobuilds/${STAGE3_FILE}" > "${OUTDIR}/${STAGE3_NAME}"
else
	echo "${STAGE3_NAME} is up to date, skipping"
fi

# make sure latest stage3 is actually good
OUR_SHA512=$(sha512sum "${OUTDIR}/${STAGE3_NAME}" | awk {'print $1'})
if [ "${OUR_SHA512}" != "${OUR_SHA512}" ]; then
  echo 'downloaded file did not match the sha512 sum'
  exit 1
fi

# get the latest portage
PORTAGE_DIR="/var/tmp/catalyst/snapshots"
PORTAGE_LIVE_MD5=$(curl -s "${MIRROR}/gentoo/snapshots/portage-latest.tar.bz2.md5sum" | awk '/portage-latest/ {print $1}')
OUR_MD5=$(md5sum "${PORTAGE_DIR}/portage-latest.tar.bz2" | awk {'print $1'})
if [[ "${PORTAGE_LIVE_MD5}" != "${OUR_MD5}" ]]; then
  echo 'downloading new portage tarball'
  curl -s "${MIRROR}/gentoo/snapshots/portage-latest.tar.bz2" > "${PORTAGE_DIR}/portage-latest.tar.bz2"
else
  echo 'portage tarball is up to date'
fi

OUR_MD5=$(md5sum "${PORTAGE_DIR}/portage-latest.tar.bz2" | awk {'print $1'})
if [[ "${PORTAGE_LIVE_MD5}" != "${OUR_MD5}" ]]; then
  echo 'downloaded file did not match the md5sum'
  exit 1
fi
