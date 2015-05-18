#!/bin/bash

# Set timezone
echo 'UTC' > /etc/timezone

# Set locale
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'en_US ISO-8859-1' >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8

# Networking!
ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
rc-update add net.lo default
rc-update add net.eth0 default

# Some rootfs stuff
grep -v rootfs /proc/mounts > /etc/mtab

# This is set in rackspaces prep, might help us
echo 'net.ipv4.conf.eth0.arp_notify = 1' >> /etc/sysctl.conf
echo 'vm.swappiness = 0' >> /etc/sysctl.conf

# What kernel is installed?
INITRD=$(find /boot -name 'initram*')
KERNEL=$(find /boot -name 'kernel*')

# Let's figure out grub
cat > /boot/grub/menu.lst << EOF
# This is a sample grub.conf for use with Genkernel, per the Gentoo handbook
# http://www.gentoo.org/doc/en/handbook/handbook-x86.xml?part=1&chap=10#doc_chap2
# If you are not using Genkernel and you need help creating this file, you
# should consult the handbook. Alternatively, consult the grub.conf.sample that
# is included with the Grub documentation.

default 0
timeout 3
splashimage=(hd0,0)/boot/grub/splash.xpm.gz

title Gentoo Linux
root (hd0,0)
kernel ${KERNEL} root=/dev/vda1 ro console=tty0 console=ttyS0
initrd ${INITRD}

# vim:ft=conf:
EOF

# And the fstab
echo '/dev/vda1 / ext4 defaults 0 0' > /etc/fstab

# Clean up
eselect news read all
eclean-dist --destructive
passwd -d root
rm -f /usr/portage/distfiles/*
rm -f /etc/ssh/ssh_host_*
rm -f /etc/resolv.conf
rm -f /root/.bash_history
rm -f /root/.nano_history
rm -f /root/.lesshst
rm -f /root/.ssh/known_hosts
for i in $(find /var/log -type f); do echo > $i; done
for i in $(find /tmp -type f); do rm -f $i; done
