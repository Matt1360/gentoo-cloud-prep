#!/bin/bash
#
# Okay, so here's some real meat.  We take a drive (as 02 said, I use a VM),
# and we spray that stage4 all over it.  Then we rub some grub (0.97) all over
# it to make it feel better, and then we box it up and ship it out.

##
## Vars
##
TARGET_DISK=vdd
TEMP_DIR=/image-prep/gentoo
TARGET_IMAGE=/var/www/reenigne-gentoo-`date +%Y-%m-%d`
MOUNT_DIR=/mnt
ORIG_DIR=`pwd`
TARBALL=/image-prep/gentoo/stage4.tar.bz2

# Okay, we have the disk, let's prep it
echo 'Building disk'
parted -s /dev/$TARGET_DISK mklabel msdos
parted -s --align=none /dev/$TARGET_DISK mkpart primary 2048s 100%
parted -s /dev/$TARGET_DISK set 1 boot on
mkfs.ext4 -F /dev/${TARGET_DISK}1

# Mount it
echo 'Mounting disk'
mount /dev/${TARGET_DISK}1 $MOUNT_DIR

# Let's localize commands now
cd $MOUNT_DIR

# Expand the stage
echo 'Expanding tarball'
tar xjpf $TARBALL -C ./

# Throw in a resolv.conf (because we download portage next)
cp /etc/resolv.conf etc/resolv.conf

# Catalyst doesn't give us portage, so that's cool
echo 'Downloading portage'
curl -s http://mirror.reenigne.net/gentoo/snapshots/portage-latest.tar.bz2 > portage-latest.tar.bz2
echo 'Expanding portage'
tar xjf portage-latest.tar.bz2 -C usr/
rm portage-latest.tar.bz2

# Clean up
echo 'Syncing; unmounting'
sync
sleep 5; # To unmount, just in case.  5 seconds is nothing next to the dd below
cd $ORIG_DIR
umount $MOUNT_DIR

# Install grub
echo 'Installing grub'
printf "device (hd0) /dev/${TARGET_DISK}\nroot (hd0,0)\nsetup (hd0)\nquit\n" | grub --batch

# Now it's unmounted, but we need to make an image!
echo 'dding image'
dd if=/dev/$TARGET_DISK of=${TEMP_DIR}/temp.raw

echo 'Converting dd image to qcow2'
qemu-img convert -c -f raw -O qcow2 ${TEMP_DIR}/temp.raw ${TARGET_IMAGE}.qcow2

echo 'Cleaning up'
rm ${TEMP_DIR}/temp.raw
