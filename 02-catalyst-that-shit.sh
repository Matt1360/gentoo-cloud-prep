#!/bin/bash
#
# This will generate the spec, and run catalyst.
# I don't know if catalyst spec files can read vars, and didn't try it.
# Oh well, doesn't really matter, I suppose
#
# Also notice, you'll have to change the actual specfile generation for
# your own scenario.  I have a VM that poops out images for me, and these
# are the fields I use.

##
## Vars
##
DATE=`date +%Y%m%d`
SPECFILE=stage4.spec
OUTFILE=/image-prep/gentoo/stage4-${DATE}.tar.bz2

# Build the spec file, first
cat > $SPECFILE << EOF
subarch: amd64
target: stage4
rel_type: default
profile: default/linux/amd64/13.0
source_subpath: stage3-amd64-latest
cflags: -O2 -pipe -march=native

pkgcache_path: /tmp/packages
kerncache_path: /tmp/kernel

# Probably best made as parameters
snapshot: latest
version_stamp: ${DATE}

# Stage 4 stuff
stage4/use: bash-completion bzip2 idm urandom ipv6 mmx sse sse2 abi_x86_32 abi_x86_64
stage4/packages: eix dev-vcs/git tmux vim sys-devel/bc cloud-init syslog-ng logrotate vixie-cron dhcpcd net-misc/curl sudo gentoolkit iproute2 grub:0
stage4/fsscript: /root/gentoo-catalyst/prep.sh
stage4/root_overlay: /root/gentoo-catalyst/root-overlay
stage4/rcadd: syslog-ng|default sshd|default vixie-cron|default cloud-config|default cloud-init-local|default cloud-init|default cloud-final|default netmount|default

boot/kernel: gentoo
boot/kernel/gentoo/sources: gentoo-sources
boot/kernel/gentoo/config: /root/gentoo-catalyst/kernel.config
boot/kernel/gentoo/extraversion: reenigne
boot/kernel/gentoo/gk_kernargs: --all-ramdisk-modules
EOF

# Run catalyst
catalyst -f $SPECFILE

# Clean up the spec file
rm $SPECFILE

# Move the outputted image
mv /var/tmp/catalyst/builds/default/stage4-amd64-${DATE}.tar.bz2 $OUTFILE
