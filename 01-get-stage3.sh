#!/usr/bin/env bash
#
# Note that I use this script to update all my current stages, and rootfs,
# but this repo is more specifically for Gentoo, so have some Gentoo.

##
## Vars
##
MIRROR="http://gentoo.osuosl.org"
OUTDIR="/var/tmp/catalyst/builds"

mkdir -p ${OUTDIR}

##
## Gentoo
##

STAGE3_NAME="stage3-amd64-latest.tar.bz2"
STAGE3_REAL_PATH=$(curl -s "${MIRROR}/releases/amd64/autobuilds/latest-stage3-amd64.txt" | awk '/stage3/ { print $1 }')
STAGE3_REAL_NAME=$(echo -n "${STAGE3_REAL_PATH}" | awk -F/ '{ print $2}')
STAGE3_URL="${MIRROR}/releases/amd64/autobuilds/current-stage3-amd64/${STAGE3_REAL_NAME}"

echo "Downloading new image - ${STAGE3_NAME}"
curl -s "${STAGE3_URL}" -o "${OUTDIR}/${STAGE3_REAL_NAME}"
curl -s "${STAGE3_URL}.DIGESTS.asc" -o "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"

# make sure latest stage3 is actually good
gkeys verify -F "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
if [[ $? != 0 ]]; then
  echo 'stage3 did not verify, removing badness'
  rm "${OUTDIR}/${STAGE3_REAL_NAME}"
  rm "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS"
  exit 1
else
  SHA512=$(grep -A1 SHA512 "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc" | grep stage3 | grep -v CONTENTS | awk '{ print $1 }')
  SHA512_REAL=$(sha512sum "${OUTDIR}/${STAGE3_REAL_NAME}" | awk '{ print $1 }')
  if [[ SHA512 != SHA512_REAL ]]; then
    echo 'shasum did not match, removing badness'
    rm "${OUTDIR}/${STAGE3_REAL_NAME}"
    rm "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
    exit 1
  fi
  # otherwise we cleanup and move on
  rm "${OUTDIR}/${STAGE3_NAME}"
  rm "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS"
  mv "${OUTDIR}/${STAGE3_REAL_NAME}" "${OUTDIR}/${STAGE3_NAME}"
fi

# get the latest portage
PORTAGE_DIR="/var/tmp/catalyst/snapshots"
PORTAGE_LIVE_MD5=$(curl -s "${MIRROR}/snapshots/portage-latest.tar.bz2.md5sum" | awk '/portage-latest/ {print $1}')
OUR_MD5=$(md5sum "${PORTAGE_DIR}/portage-latest.tar.bz2" | awk {'print $1'})
if [[ "${PORTAGE_LIVE_MD5}" != "${OUR_MD5}" ]]; then
  echo 'downloading new portage tarball'
  curl -s "${MIRROR}/snapshots/portage-latest.tar.bz2" > "${PORTAGE_DIR}/portage-latest.tar.bz2"
else
  echo 'portage tarball is up to date'
fi

OUR_MD5=$(md5sum "${PORTAGE_DIR}/portage-latest.tar.bz2" | awk {'print $1'})
if [[ "${PORTAGE_LIVE_MD5}" != "${OUR_MD5}" ]]; then
  echo 'downloaded file did not match the md5sum'
  exit 1
fi
