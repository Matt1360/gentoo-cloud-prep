#!/usr/bin/env bash
#
# Okay, so here's some real meat.  We take a drive (as 02 said, I use a VM),
# and we spray that stage4 all over it.  Then we rub some grub (0.97) all over
# it to make it feel better, and then we box it up and ship it out.

##
## Vars
##
TEMP_DIR=~/tmp/catalyst/gentoo
TARGET_IMAGE=/root/openstack-gentoo-`date +%Y-%m-%d`
MOUNT_DIR=/mnt
DATE=$(date +%Y%m%d)
ORIG_DIR=$(pwd)
TARBALL=~/tmp/catalyst/gentoo/stage4-${DATE}.tar.bz2

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

# Let's localize commands now
cd ${MOUNT_DIR}

# Expand the stage
echo 'Expanding tarball'
tar xjpf ${TARBALL} -C ./

# Throw in a resolv.conf (because we download portage next)
cp /etc/resolv.conf etc/resolv.conf

# Catalyst doesn't give us portage, so that's cool
echo 'Downloading portage'
if [[ ! -f /var/tmp/catalyst/snapshots/portage-latest.tar.bz2 ]]; then
  echo 'the tarball you downloaded in the 01 script is missing'
  exit 1
fi
echo 'Expanding portage'
tar xjf /var/tmp/catalyst/snapshots/portage-latest.tar.bz2 -C usr/

# Clean up
echo 'Syncing; unmounting'
sync
cd ${ORIG_DIR}
umount ${MOUNT_DIR}

# Install grub
echo 'Installing grub'
printf "device (hd0) ${BLOCK_DEV}\nroot (hd0,0)\nsetup (hd0)\nquit\n" | grub --batch

# get rid of block mapping
losetup -d ${BLOCK_DEV}

echo 'Converting raw image to qcow2'
qemu-img convert -c -f raw -O qcow2 ${TEMP_DIR}/gentoo_root.img ${TARGET_IMAGE}.qcow2

echo 'Cleaning up'
rm ${TEMP_DIR}/gentoo_root.img
