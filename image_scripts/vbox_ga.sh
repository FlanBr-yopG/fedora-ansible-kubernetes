#!/bin/bash

mkdir /media/vbadditions
mount -t iso9660 -o loop /tmp/VBoxGuestAdditions.iso /media/vbadditions

export KERN_DIR=/usr/src/kernels/`uname -r`
# Install the drivers
/media/vbadditions/VBoxLinuxAdditions.run

umount /media/vbadditions
rm -rf /media/vbadditions /tmp/VBoxGuestAdditions.iso

#