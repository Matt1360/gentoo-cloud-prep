#!/usr/bin/env bash
#
# Okay, so here's some real meat.  We take a drive (as 02 said, I use a VM),
# and we spray that stage4 all over it.  Then we rub some grub (0.97) all over
# it to make it feel better, and then we box it up and ship it out.

set -e -u -x

# Vars
export TEMP_DIR=${TEMP_DIR:-'/root/tmp/catalyst/gentoo'}
export MOUNT_DIR=${MOUNT_DIR:-'/mnt'}
export DATE=${DATE:-"$(date +%Y%m%d)"}
export TARBALL=${TARBALL:-"/root/tmp/catalyst/gentoo/stage4-${DATE}.tar.bz2"}
# profiles supported are as follows
# default/linux/amd64/13.0
# default/linux/amd64/13.0/no-multilib
# hardened/linux/amd64
# hardened/linux/amd64/no-multilib
# hardened/linux/amd64/selinux (eventually)
# hardened/linux/amd64/no-multilib/selinux (eventually)
export PROFILE=${PROFILE:-"default/linux/amd64/13.0"}
if [[ "${PROFILE}" == "default/linux/amd64/13.0" ]]; then
  PROFILE_SHORTNAME="amd64-default"
elif [[ "${PROFILE}" == "default/linux/amd64/13.0/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-nomultilib"
elif [[ "${PROFILE}" == "hardened/linux/amd64" ]]; then
  PROFILE_SHORTNAME="amd64-hardened"
elif [[ "${PROFILE}" == "hardened/linux/amd64/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-hardened-nomulitlib"
else
  echo 'invalid profile, exiting'
  exit 1
fi
export TARGET_IMAGE=${TARGET_IMAGE:-"/root/openstack-${PROFILE_SHORTNAME}-${DATE}.qcow2"}

# create a raw partition and do stuff with it
fallocate -l 5G "${TEMP_DIR}/gentoo_root.img"
losetup -f "${TEMP_DIR}/gentoo_root.img"
BLOCK_DEV=$(losetup | grep 'gentoo_root.img' | awk '{print $1}')

# Okay, we have the disk, let's prep it
echo 'Building disk'
parted -s ${BLOCK_DEV} mklabel msdos
parted -s --align=none ${BLOCK_DEV} mkpart primary 2048s 100%
parted -s ${BLOCK_DEV} set 1 boot on
mkfs.ext4 -F ${BLOCK_DEV}p1

# Mount it
echo 'Mounting disk'
mount ${BLOCK_DEV}p1 ${MOUNT_DIR}

# Expand the stage
echo 'Expanding tarball'
tar xjpf ${TARBALL} -C ${MOUNT_DIR}

# Throw in a resolv.conf (because we download portage next)
cp /etc/resolv.conf "${MOUNT_DIR}"/etc/resolv.conf

echo 'Expanding portage'
tar xjf /var/tmp/catalyst/snapshots/portage-latest.tar.bz2 -C "${MOUNT_DIR}"/usr/

# Install grub
grub2-install ${BLOCK_DEV} --boot-directory ${MOUNT_DIR}/boot

# Clean up
echo 'Syncing; unmounting'
sync
umount ${MOUNT_DIR}

# get rid of block mapping
losetup -d ${BLOCK_DEV}

echo 'Converting raw image to qcow2'
qemu-img convert -c -f raw -O qcow2 ${TEMP_DIR}/gentoo_root.img ${TARGET_IMAGE}

echo 'Cleaning up'
rm ${TEMP_DIR}/gentoo_root.img
