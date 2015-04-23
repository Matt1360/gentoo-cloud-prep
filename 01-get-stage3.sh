#!/bin/bash
# Note that I use this script to update all my current stages, and rootfs,
# but this repo is more specifically for Gentoo, so have some Gentoo.

##
## Vars
##
MIRROR=http://mirror.reenigne.net
OUTDIR=/var/tmp/catalyst/builds

##
## Gentoo
##

name=stage3-amd64-latest.tar.bz2
stage3_file=`curl -s ${MIRROR}/gentoo/releases/amd64/autobuilds/latest-stage3-amd64.txt | awk '/stage3/ { print $1 }'`
live_sha512=`curl -s ${MIRROR}/gentoo/releases/amd64/autobuilds/${stage3_file}.DIGESTS | awk '/SHA512 HASH/{getline;print}' | grep -iv 'contents' | awk {'print $1'}`
our_sha512=`sha512sum /var/tmp/catalyst/builds/$name | awk {'print $1'}`

if [ "$live_sha512" != "$our_sha512" ]
then
	echo "Downloading new image - $name"
	curl -s ${MIRROR}/gentoo/releases/amd64/autobuilds/$stage3_file > ${OUTDIR}/$name
else
	echo "$name is up to date, skipping"
fi
