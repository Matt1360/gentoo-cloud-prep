#!/usr/bin/env bash
#
# This will generate the spec, and run catalyst.
# I don't know if catalyst spec files can read vars, and didn't try it.
# Oh well, doesn't really matter, I suppose
#
# Also notice, you'll have to change the actual specfile generation for
# your own scenario.  I have a VM that poops out images for me, and these
# are the fields I use.

set -e -u -x -o pipefail

# Vars
export DATE=${DATE:-"$(date +%Y%m%d)"}
export OUTDIR=${OUTDIR:-"/root/tmp/catalyst/gentoo"}
export GIT_BASE_DIR=${GIT_BASE_DIR:-$( cd "$( dirname ${BASH_SOURCE[0]} )" && pwd )}
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
  SOURCE_SUBPATH="stage3-amd64-current"
  KERNEL_SOURCES="gentoo-sources"
elif [[ "${PROFILE}" == "default/linux/amd64/13.0/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-default-nomultilib"
  SOURCE_SUBPATH="stage3-amd64-nomultilib-current"
  KERNEL_SOURCES="gentoo-sources"
elif [[ "${PROFILE}" == "hardened/linux/musl/amd64" ]]; then
  PROFILE_SHORTNAME="amd64-hardened-musl"
  SOURCE_SUBPATH="musl/hardened/amd64/stage3-amd64-musl-hardened"
  KERNEL_SOURCES="hardened-sources"
elif [[ "${PROFILE}" == "hardened/linux/amd64" ]]; then
  PROFILE_SHORTNAME="amd64-hardened"
  SOURCE_SUBPATH="stage3-amd64-hardened-current"
  KERNEL_SOURCES="hardened-sources"
elif [[ "${PROFILE}" == "hardened/linux/amd64/no-multilib" ]]; then
  PROFILE_SHORTNAME="amd64-hardened-nomultilib"
  SOURCE_SUBPATH="stage3-amd64-hardened-nomultilib-current"
  KERNEL_SOURCES="hardened-sources"
else
  echo 'invalid profile, exiting'
  exit 1
fi
export OUTFILE=${OUTFILE:-"${OUTDIR}/stage4-${PROFILE_SHORTNAME}-${DATE}.tar.bz2"}
export SPECFILE=${SPECFILE:-"/root/tmp/catalyst/stage4-${PROFILE_SHORTNAME}.spec"}
mkdir -p "${OUTDIR}"

# Build the spec file, first
cat > "${SPECFILE}" << EOF
subarch: amd64
target: stage4
rel_type: ${PROFILE_SHORTNAME}
profile: ${PROFILE}
source_subpath: ${SOURCE_SUBPATH}
cflags: -O2 -pipe -march=core2

pkgcache_path: /tmp/packages-${PROFILE_SHORTNAME}
kerncache_path: /tmp/kernel-${PROFILE_SHORTNAME}
portage_confdir: ${GIT_BASE_DIR}/portage_overlay
portage_overlay: ~/overlays/musl

# Probably best made as parameters
snapshot: current
version_stamp: ${DATE}

# Stage 4 stuff
stage4/use: bash-completion bzip2 idm ipv6 mmx sse sse2 urandom -nls -fortran
stage4/packages: app-admin/logrotate app-admin/sudo app-admin/syslog-ng app-editors/vim app-emulation/cloud-init app-portage/eix app-portage/gentoolkit net-misc/dhcpcd sys-apps/dmidecode sys-apps/gptfdisk sys-apps/iproute2 sys-apps/lsb-release sys-boot/grub:2 sys-devel/bc sys-power/acpid sys-process/cronie
stage4/fsscript: files/prep.sh
stage4/root_overlay: root-overlay
stage4/rcadd: syslog-ng|default sshd|default cronie|default cloud-config|default cloud-init-local|default cloud-init|default cloud-final|default netmount|default acpid|default dhcpcd|default net.lo|default

boot/kernel: gentoo
boot/kernel/gentoo/sources: ${KERNEL_SOURCES}
boot/kernel/gentoo/config: files/kernel-${PROFILE_SHORTNAME}.config
boot/kernel/gentoo/extraversion: openstack
boot/kernel/gentoo/gk_kernargs: --all-ramdisk-modules --makeopts=-j6

# all of the cleanup...
stage4/unmerge:
  sys-kernel/genkernel
  sys-kernel/gentoo-sources
  sys-kernel/hardened-sources

stage4/empty:
  /root/.ccache
  /tmp
  /usr/portage/distfiles
  /usr/src
  /var/cache/edb/dep
  /var/cache/genkernel
  /var/empty
  /var/run
  /var/state
  /var/tmp

stage4/rm:
  /etc/*-
  /etc/*.old
  /etc/ssh/ssh_host_*
  /root/.*history
  /root/.lesshst
  /root/.ssh/known_hosts
  /root/.viminfo
  # Remove any generated stuff by genkernel
  /usr/share/genkernel
  # This is 3MB of crap for each copy
  /usr/lib64/python*/site-packages/gentoolkit/test/eclean/testdistfiles.tar.gz
EOF

# Run catalyst
catalyst -f "${SPECFILE}"

# Clean up the spec file
rm "${SPECFILE}"

# Move the outputted image
mv "/var/tmp/catalyst/builds/${PROFILE_SHORTNAME}/stage4-amd64-${DATE}.tar.bz2" "${OUTFILE}"
