#!/usr/bin/env bash
#
# Note that I use this script to update all my current stages, and rootfs,
# but this repo is more specifically for Gentoo, so have some Gentoo.

set -e -u -x

# Vars
export MIRROR=${MIRROR:-"http://gentoo.osuosl.org"}
export OUTDIR=${OUTDIR:-"/var/tmp/catalyst/builds"}
export PORTAGE_DIR=${PORTAGE_DIR:-"/var/tmp/catalyst/snapshots"}
# profiles supported are as follows
# default/linux/amd64/13.0
# default/linux/amd64/13.0/no-multilib
# hardened/linux/amd64
# hardened/linux/amd64/no-multilib
# hardened/linux/amd64/selinux (eventually)
# hardened/linux/amd64/no-multilib/selinux (eventually)
export PROFILE=${PROFILE:-"default/linux/amd64/13.0"}

mkdir -p ${OUTDIR}

if [[ "${PROFILE}" == "default/linux/amd64/13.0" ]]; then
  STAGE3_NAME="stage3-amd64-current.tar.bz2"
  STAGE3_REAL_PATH=$(curl -s "${MIRROR}/releases/amd64/autobuilds/latest-stage3-amd64.txt" | awk '/stage3/ { print $1 }')
  STAGE3_REAL_NAME=$(echo -n "${STAGE3_REAL_PATH}" | awk -F/ '{ print $2}')
  STAGE3_URL="${MIRROR}/releases/amd64/autobuilds/current-stage3-amd64/${STAGE3_REAL_NAME}"
elif [[ "${PROFILE}" == "default/linux/amd64/13.0/no-multilib" ]]; then
  STAGE3_NAME="stage3-amd64-nomultilib-current.tar.bz2"
  STAGE3_REAL_PATH=$(curl -s "${MIRROR}/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib.txt" | awk '/stage3/ { print $1 }')
  STAGE3_REAL_NAME=$(echo -n "${STAGE3_REAL_PATH}" | awk -F/ '{ print $2}')
  STAGE3_URL="${MIRROR}/releases/amd64/autobuilds/current-stage3-amd64-nomultilib/${STAGE3_REAL_NAME}"
elif [[ "${PROFILE}" == "hardened/linux/amd64" ]]; then
  STAGE3_NAME="stage3-amd64-hardened-current.tar.bz2"
  STAGE3_REAL_PATH=$(curl -s "${MIRROR}/releases/amd64/autobuilds/latest-stage3-amd64-hardened.txt" | awk '/hardened/ { print $1 }')
  STAGE3_REAL_NAME=$(echo -n "${STAGE3_REAL_PATH}" | awk -F/ '{ print $3}')
  STAGE3_URL="${MIRROR}/releases/amd64/autobuilds/current-stage3-amd64-hardened/${STAGE3_REAL_NAME}"
elif [[ "${PROFILE}" == "hardened/linux/amd64/no-multilib" ]]; then
  STAGE3_NAME="stage3-amd64-hardened-nomultilib-current.tar.bz2"
  STAGE3_REAL_PATH=$(curl -s "${MIRROR}/releases/amd64/autobuilds/latest-stage3-amd64-hardened+nomultilib.txt" | awk '/hardened/ { print $1 }')
  STAGE3_REAL_NAME=$(echo -n "${STAGE3_REAL_PATH}" | awk -F/ '{ print $3}')
  STAGE3_URL="${MIRROR}/releases/amd64/autobuilds/current-stage3-amd64-hardened+nomultilib/${STAGE3_REAL_NAME}"
else
  echo 'invalid profile, exiting'
  exit 1
fi

curl -s "${STAGE3_URL}.DIGESTS.asc" -o "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
gkeys verify -F "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
STATUS=$?
if [[ ${STATUS} != 0 ]]; then
  echo 'stage3 did not verify, removing badness'
  rm "${OUTDIR}/${STAGE3_REAL_NAME}"
  rm "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
  exit 1
fi

SHA512=$(grep -A1 SHA512 "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc" | grep stage3 | grep -v CONTENTS | awk '{ print $1 }')
SHA512_REAL=$(sha512sum "${OUTDIR}/${STAGE3_NAME}" | awk '{ print $1 }')
if [[ "${SHA512}" != "${SHA512_REAL}" ]]; then
  echo "Downloading new image - ${STAGE3_REAL_NAME}"
  curl -s "${STAGE3_URL}" -o "${OUTDIR}/${STAGE3_REAL_NAME}"
  SHA512=$(grep -A1 SHA512 "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc" | grep stage3 | grep -v CONTENTS | awk '{ print $1 }')
  SHA512_REAL=$(sha512sum "${OUTDIR}/${STAGE3_REAL_NAME}" | awk '{ print $1 }')
  if [[ "${SHA512}" != "${SHA512_REAL}" ]]; then
    echo 'shasum did not match, removing badness'
    rm "${OUTDIR}/${STAGE3_REAL_NAME}"
    rm "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
    exit 1
  fi
  # otherwise we cleanup and move on
  if [[ -f "${OUTDIR}/${STAGE3_NAME}" ]]; then
    rm "${OUTDIR}/${STAGE3_NAME}"
  fi
  rm "${OUTDIR}/${STAGE3_REAL_NAME}.DIGESTS.asc"
  mv "${OUTDIR}/${STAGE3_REAL_NAME}" "${OUTDIR}/${STAGE3_NAME}"
fi


# get the latest portage
PORTAGE_LIVE_MD5=$(curl -s "${MIRROR}/snapshots/portage-latest.tar.bz2.md5sum" | awk '/portage-latest/ {print $1}')
OUR_MD5=$(md5sum "${PORTAGE_DIR}/portage-latest.tar.bz2" | awk {'print $1'})
if [[ "${PORTAGE_LIVE_MD5}" != "${OUR_MD5}" ]]; then
  echo 'downloading new portage tarball'
  curl -s "${MIRROR}/snapshots/portage-latest.tar.bz2" -o "${PORTAGE_DIR}/portage-latest.tar.bz2"
  curl -s "${MIRROR}/snapshots/portage-latest.tar.bz2.gpgsig" -o "${PORTAGE_DIR}/portage-latest.tar.bz2.gpgsig"
  gkeys verify -F "${PORTAGE_DIR}/portage-latest.tar.bz2"
  STATUS=$?
  if [[ ${STATUS} != 0 ]]; then
    echo 'tarball did not verify, removing badness'
    rm "${PORTAGE_DIR}/portage-latest.tar.bz2"
    rm "${PORTAGE_DIR}/portage-latest.tar.bz2.gpgsig"
    exit 1
  elif [[ ${STATUS} == 0 ]]; then
    echo 'tarball verified'
    rm "${PORTAGE_DIR}/portage-latest.tar.bz2.gpgsig"
  fi
else
  echo 'portage tarball is up to date'
fi
